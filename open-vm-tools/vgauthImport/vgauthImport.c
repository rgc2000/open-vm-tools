/*********************************************************
 * Copyright (c) 2012,2018-2021 VMware, Inc. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation version 2.1 and no later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the Lesser GNU General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA.
 *
 *********************************************************/

/*
 * vgauthImport.c --
 *
 *      Command line tool to import vgauth config data from the
 *      namespace DB and apply it to the running vgauth service.
 */

#include <stdio.h>
#include <stdlib.h>
#include <glib.h>

#include "vmware.h"
#include "vmcheck.h"
#include "util.h"
#include "dynbuf.h"

#include "VGAuthCommon.h"
#include "VGAuthError.h"
#include "VGAuthAuthentication.h"
#include "VGAuthAlias.h"
#include "vmware/tools/guestrpc.h"
#ifdef _WIN32
#include "vmware/tools/win32util.h"
#endif

#define  VGAUTHIMPORT_APP_NAME "vgauthImport"

#define NOT_VMWARE_ERROR "Failed sending message to VMware.\n"

static Bool ProcessNamespace(char *namespace);

#define NSDB_PRIV_GET_VALUES_CMD "namespace-priv-get-values"
#define NSDB_PRIV_SET_KEYS_CMD "namespace-priv-set-keys"

/*
 * The namspaceDB key names used.
 */

/*
 * These 5 are set by the solution on the vSphere side.
 */
#define KEY_NAME_CERT "certificate"
#define KEY_NAME_SUBJECT "subject"
#define KEY_NAME_COMMENT "comment"
#define KEY_NAME_USER "guestUsername"
#define KEY_NAME_ADDMAPPED "addMapped"

/*
 * This is set by this tool to allow the solution to know when
 * the data was imported.
 */
#define KEY_NAME_IMPORTED "imported"


/*
 * The underlying APIs will return values in the order they're
 * queried.  This structure simplifies deserializing the answers.
 */
typedef struct {
   const char *keyName;
   char *val;
} KeyNameValue;

static KeyNameValue nameVals[] = {
   { KEY_NAME_CERT, NULL},
   { KEY_NAME_SUBJECT, NULL},
   { KEY_NAME_COMMENT, NULL},
   { KEY_NAME_USER, NULL},
   { KEY_NAME_ADDMAPPED, NULL},
};


static gboolean verboseLogFlag = FALSE;
static gchar *gAppName = NULL;

static const gchar *usageMsg = "namespaceID";
static const gchar *summaryMsg = "";

/*
 ******************************************************************************
 * PrintUsage --                                                         */ /**
 *
 * Prints the usage mesage.
 *
 ******************************************************************************
 */

static void
PrintUsage(GOptionContext *optCtx)
{
   gchar *usage;

   usage = g_option_context_get_help(optCtx, TRUE, NULL);
   g_printerr("%s", usage);
   g_free(usage);
}


/*
 ******************************************************************************
 * vgauthLog --                                                          */ /**
 *
 * VGAuth error log handler.  Catches any noise generated by VGAuth
 * lib or glib underneath it.
 *
 * @param[in]  logDomain   The source domain of the error message.
 * @param[in]  loglevl     The priority level of the error.
 * @param[in]  msg         The error message.
 * @param[in]  userData    Any user-supplied data.
 *
 ******************************************************************************
 */

static void
vgauthLog(const char *logDomain,
          int loglevel,
          const char *msg,
          void *userData)
{
   /*
    * Ignore debug and message levels.
    */
   if (loglevel &
       (G_LOG_LEVEL_ERROR | G_LOG_LEVEL_CRITICAL | G_LOG_LEVEL_WARNING)) {
      fprintf(stderr, "VGAuth error: [%s] %s\n", logDomain, msg);
   }
}


/*
 ******************************************************************************
 * ProcessQueryReply --                                                  */ /**
 *
 * Processes the return data from the namespace-get call.
 *
 * Parses the data coming back from the namespace-get-values call, and
 * updates the VGAuth alias store with the information.
 *
 * @param[in]  result    The raw data.  UTF-8 bytestream with embedded NULs.
 * @param[in]  ersultLen The length of the data.
 *
 * @return TRUE if successful, FALSE otherwise.
 *
 ******************************************************************************
 */

static Bool
ProcessQueryReply(char *result,
                  size_t resultLen)
{
   char *p = result;
   VGAuthAliasInfo ai;
   char *pemCert = NULL;
   char *userName = NULL;
   Bool addMapped = FALSE;
   Bool status = TRUE;
   VGAuthError vgErr;
   VGAuthContext *ctx = NULL;
   int i;
   int numMapped = 0;
   VGAuthMappedAlias *maList = NULL;
   Bool alreadyExists = FALSE;

   ASSERT(result);
   ai.subject.type = VGAUTH_SUBJECT_NAMED;
   ai.comment = "";
   ai.subject.val.name = NULL;

   /*
    * Deserialize the results.
    */
   for (i = 0; i < ARRAYSIZE(nameVals); i++) {
      nameVals[i].val = Util_SafeStrdup(p);
      p += strlen(p) + 1;
      ASSERT(p <= (result + resultLen));
   }

   /*
    * Rename them so the VGAuth APIs have sane variable names.
    */
   pemCert = nameVals[0].val;
   ai.subject.val.name = nameVals[1].val;
   ai.comment = nameVals[2].val;
   userName = nameVals[3].val;
   addMapped = (*(nameVals[4].val) == 't' || *(nameVals[4].val) == 'T');

   if (verboseLogFlag) {
      printf("Certficate: \n%s\n", pemCert);
      printf("Subject: %s\n", ai.subject.val.name);
      printf("Comment: %s\n", ai.comment);
      printf("GuestUsername: %s\n", userName);
      printf("AddMapped: %d\n", addMapped);
   }


   /*
    * Verify we got at least the args we require.
    */
   if ((NULL == userName) || (NULL == pemCert) ||
       (NULL == ai.subject.val.name)) {
      fprintf(stderr, "Missing required keys\n");
      status = FALSE;
      goto done;
   }

   /*
    * Clear out extra whitespace.
    *
    * XXX VGAuth will clean up any whitespace in the cert, so this
    * is needed to properly match.  May have to go to the full cert clean
    * that vgauth uses (base64 decode, base64 encode), or compare
    * the base64 decoded data.
    */
   g_strstrip(pemCert);

   /*
    * Now tell VGAuth.
    */
   VGAuth_SetLogHandler(vgauthLog, NULL, 0, NULL);
   vgErr = VGAuth_Init(VGAUTHIMPORT_APP_NAME, 0, NULL, &ctx);
   if (VGAUTH_FAILED(vgErr)) {
      fprintf(stderr, "Failed to init VGAuth context\n");
      status = FALSE;
      goto done;
   }

   /*
    * Make sure we don't already have the entry.
    *
    * We only care for the addMapped case, since a duplicate mapped
    * entry is an error.  In the non-mapped case, a dup is a no-op.
    */
   if (addMapped) {
      vgErr = VGAuth_QueryMappedAliases(ctx, 0, NULL,
                                        &numMapped, &maList);
      if (VGAUTH_FAILED(vgErr)) {
         fprintf(stderr, "VGAuth_QueryMappedAliases failed.\n");
         status = FALSE;
         goto done;
      }

      for (i = 0; i < numMapped; i++) {
         if ((strcmp(pemCert, maList[i].pemCert) == 0) &&
             (strcmp(userName, maList[i].userName) == 0)) {
            int j;

            for (j = 0; j < maList[i].numSubjects; j++) {
               if (maList[i].subjects[j].type != VGAUTH_SUBJECT_NAMED) {
                  continue;
               }
               if (strcmp(ai.subject.val.name,
                          maList[i].subjects[j].val.name) == 0) {
                  fprintf(stderr,
                          "Entry already exists; just updating 'import' timestamp\n");
                  alreadyExists = TRUE;
               }
            }
         }
      }
   }

   /*
    * XXX
    *
    * Support a 'clobber' cmdline arg, that does a remove/add?
    * Should only be useful for a comment tweak.
    */

   if (!alreadyExists) {
      vgErr = VGAuth_AddAlias(ctx, userName, addMapped,
                              pemCert, &ai, 0, NULL);
      if (VGAUTH_FAILED(vgErr)) {
         fprintf(stderr, "Failed to set VGAuth data\n");
         status = FALSE;
         goto done;
      }
   } else {
      /*
       * XXX
       *
       * Lets return success, so the timestamp still gets updated.
       * May want to tie this to a cmdline flag.
       */
      status = TRUE;
   }

done:
   if (NULL != ctx) {
      VGAuth_Shutdown(ctx);
   }
   for (i = 0; i < ARRAYSIZE(nameVals); i++) {
      free(nameVals[i].val);
   }
   VGAuth_FreeMappedAliasList(numMapped, maList);

   return status;
}


/*
 ******************************************************************************
 * SetImportTime --                                                      */ /**
 *
 * Updates the namespace 'import' value with the current time.
 *
 * @param[in]  namespace  The namespace to be updated.
 *
 * @return TRUE if successful, FALSE otherwise.
 *
 ******************************************************************************
 */

static Bool
SetImportTime(char *namespace)
{
   char *curTimeStr;
   Bool status;
   DynBuf buf;
   char *result = NULL;
   size_t resultLen;
   GTimeVal now;

   /*
    * Use ISO timestamp to be VIM friendly.
    */
   g_get_current_time(&now);
   curTimeStr = g_time_val_to_iso8601(&now);

   DynBuf_Init(&buf);

   /*
    * Format is:
    *
    * namespace-set-keys <namespace>\0<numOps>\0<op>\0<key>\0<value>\0<oldVal>
    *
    * We have just a single op, and want to always set the value, clobbering
    * anything already there.
    */
   if (!DynBuf_Append(&buf, NSDB_PRIV_SET_KEYS_CMD,
                      strlen(NSDB_PRIV_SET_KEYS_CMD)) ||
       !DynBuf_Append(&buf, " ", 1) ||
       !DynBuf_AppendString(&buf, namespace) ||
       !DynBuf_AppendString(&buf, "1") || // numOps
       !DynBuf_AppendString(&buf, "0") || // op 0 == setAlways
       !DynBuf_AppendString(&buf, KEY_NAME_IMPORTED) ||
       !DynBuf_AppendString(&buf, curTimeStr) ||
       !DynBuf_Append(&buf, "", 1)) {                 // NULL for set always
      fprintf(stderr, "Could not construct update request buffer\n");
      status = FALSE;
   } else {
      status = RpcChannel_SendOneRaw(DynBuf_Get(&buf),
                                     DynBuf_GetSize(&buf),
                                     &result, &resultLen);
      if (!status) {
         fprintf(stderr, "Failed to update %s field after processing namespace '%s\n",
                 KEY_NAME_IMPORTED, namespace);
      }
      free(result);
   }
   g_free(curTimeStr);
   DynBuf_Destroy(&buf);

   return status;
}


/*
 ******************************************************************************
 * QueryNamespace --                                                     */ /**
 *
 * Queries the namespace DB for the keys we want.
 *
 * @param[in]  namespace      The namespace name.
 * @param[out] resultData     The result data.
 * @param[out] resultDataLen  The length of the result data.
 *
 * @return TRUE if successful, FALSE otherwise.
 *
 ******************************************************************************
 */

static Bool
QueryNamespace(char *namespace,
               char **resultData,
               size_t *resultDataLen)
{
   char *result = NULL;
   size_t resultLen = 0;
   DynBuf buf;
   int i;
   Bool status = FALSE;

   ASSERT(namespace);

   DynBuf_Init(&buf);

   /*
    * Format is
    *
    * namespace-get-values <namespace>\0<key>\0...
    *
    */
   if (!DynBuf_Append(&buf, NSDB_PRIV_GET_VALUES_CMD,
                      strlen(NSDB_PRIV_GET_VALUES_CMD)) ||
       !DynBuf_Append(&buf, " ", 1) ||
       !DynBuf_AppendString(&buf, namespace)) {
      fprintf(stderr, "Could not contruct request buffer\n");
      goto done;
   }
   for (i = 0; i < ARRAYSIZE(nameVals); i++) {
      if (!DynBuf_AppendString(&buf, nameVals[i].keyName)) {
         fprintf(stderr, "Could not contruct request buffer\n");
         goto done;
      }
   }

   status = RpcChannel_SendOneRaw(DynBuf_Get(&buf), DynBuf_GetSize(&buf),
                                  &result, &resultLen);

done:
   *resultData = result;
   *resultDataLen = resultLen;
   DynBuf_Destroy(&buf);
   return status;
}


/*
 ******************************************************************************
 * ProcessNamespace --                                                   */ /**
 *
 * Processes the data in 'namespace'.  Queries the namespace DB for
 * the keys we want, sends them to VGAuth, and updates the namespace
 * with a timestamp noting when the data was processed.
 *
 * @param[in]  namespace   The namespace name.
 *
 * @return TRUE if successful, FALSE otherwise.
 *
 ******************************************************************************
 */

static Bool
ProcessNamespace(char *namespace)
{
   char *result = NULL;
   size_t resultLen = 0;
   Bool status = FALSE;

   ASSERT(namespace);

   status = QueryNamespace(namespace, &result, &resultLen);

   if (!status) {
      /*
       * Underlying error message works just fine so use it.
       */
      fprintf(stderr, "Error: %s\n", result ? result : "NULL");
      fprintf(stderr, "Failed to read namespace '%s'\n", namespace);
   } else {
      if (resultLen == 0) {
         fprintf(stderr, "Error: No keys found in namespace '%s'\n", namespace);
      } else {
         status = ProcessQueryReply(result, resultLen);

         if (status ) {
            status = SetImportTime(namespace);
         } else {
            fprintf(stderr,
                    "Failed to import vgauth record from namespace '%s'\n",
                    namespace);
         }
      }
   }

   free(result);

   return status;
}


/*
 ******************************************************************************
 * main --                                                               */ /**
 *
 * Main entry point.
 *
 * @param[in]  argc  Number of args.
 * @param[in]  argv  The args.
 *
 ******************************************************************************
 */

int
main(int argc, char *argv[])
{
   int argcCopy;
   char **argvCopy;
   GError *gErr = NULL;
   int success = -1;
   const GOptionEntry options[] = {
      { "verbose", 'v', 0, G_OPTION_ARG_NONE, &verboseLogFlag,
        "Verbose logging mode", NULL },
      { NULL },
   };
   GOptionContext *optCtx;
#ifdef _WIN32
   WinUtil_EnableSafePathSearching(TRUE);
#endif

   /*
    * The options parser needs to modify these, and using the variables
    * coming into main doesn't work.
    */
   argcCopy = argc;
   argvCopy = argv;

   gAppName = g_path_get_basename(argv[0]);

   g_set_prgname(gAppName);
   optCtx = g_option_context_new(usageMsg);
   g_option_context_set_summary(optCtx, summaryMsg);
   g_option_context_add_main_entries(optCtx, options, NULL);

   /*
    * Check if environment is VM
    */
   if (!VmCheck_IsVirtualWorld()) {
      g_printerr("Error: %s must be run inside a virtual machine"
                 " on a VMware hypervisor product.\n", gAppName);
      goto out;
   }

   if (!g_option_context_parse(optCtx, &argcCopy, &argvCopy, &gErr)) {
      fprintf(stderr, "%s: %s\n", gAppName, gErr->message);
      g_error_free(gErr);
      goto out;
   }

   if (argc < 2) {
      PrintUsage(optCtx);
      goto out;
   }

   success = ProcessNamespace(argv[1]) ? 0 : 1;

out:
   g_option_context_free(optCtx);
   g_free(gAppName);

   return success;
}

