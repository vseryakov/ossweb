/*
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://mozilla.org/
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and limitations
 * under the License.
 *
 * Alternatively, the contents of this file may be used under the terms
 * of the GNU General Public License (the "GPL"), in which case the
 * provisions of GPL are applicable instead of those above.  If you wish
 * to allow use of your version of this file only under the terms of the
 * GPL and not to allow others to use your version of this file under the
 * License, indicate your decision by deleting the provisions above and
 * replace them with the notice and other provisions required by the GPL.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under either the License or the GPL.
 */

#include <stdlib.h>
#include <stdio.h>
#include <memory.h>
#include <security/pam_appl.h>

struct pam_cred {
  char *username;
  char *password;
};

/*
 *----------------------------------------------------------------------
 *
 * pam_conv --
 *
 * PAM conversation function
 * Accepts: number of messages
 *	    vector of messages
 *	    pointer to response return
 *	    application data
 *
 * Results:
 *      PAM_SUCCESS if OK, response vector filled in, else PAM_CONV_ERR
 *
 * Side effects:
 *      None.
 *
 *----------------------------------------------------------------------
 */

static int
pam_conv(int msgs, const struct pam_message **msg, struct pam_response **resp, void *appdata)
{
    int i;
    struct pam_cred *cred = (struct pam_cred *) appdata;
    struct pam_response *reply = malloc(sizeof (struct pam_response) * msgs);

    for (i = 0; i < msgs; i++) {
        switch (msg[i]->msg_style) {
        case PAM_PROMPT_ECHO_ON:	/* assume want user name */
            reply[i].resp_retcode = PAM_SUCCESS;
            reply[i].resp = strdup(cred->username);
            break;

        case PAM_PROMPT_ECHO_OFF:	/* assume want password */
            reply[i].resp_retcode = PAM_SUCCESS;
            reply[i].resp = strdup(cred->password);
            break;

        case PAM_TEXT_INFO:
        case PAM_ERROR_MSG:
            reply[i].resp_retcode = PAM_SUCCESS;
            reply[i].resp = NULL;
            break;

        default:			/* unknown message style */
            free(reply);
            return PAM_CONV_ERR;
        }
    }
    *resp = reply;
    return PAM_SUCCESS;
}

int main(int argc, char *argv[])
{
    int rc;
    pam_handle_t *hdl;
    struct pam_conv conv;
    struct pam_cred cred;

    if (argc < 4) {
        printf("%s service user passwd\n", argv[0]);
        exit(1);
    }

    conv.conv = &pam_conv;
    conv.appdata_ptr = &cred;
    cred.username = argv[2];
    cred.password = argv[3];

    rc = pam_start(argv[1], cred.username, &conv, &hdl);

    if (rc == PAM_SUCCESS) {
        rc = pam_authenticate(hdl, 0);
    }
    if (rc == PAM_SUCCESS) {
        pam_acct_mgmt(hdl, 0);
    }
    pam_end(hdl, rc);

    exit(rc == PAM_SUCCESS ? 0 : 1);
}

