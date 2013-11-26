/*
    pam_pop3

    Authentication over OP3 server

    Initial version by by Schlomo Schapiro (schapiro@huji.ac.il)

    Modified and imporved by Vlad Seryakov vlad@crystalballinc.com

*/

#include <stdlib.h>
#include <stdio.h>
#include <syslog.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <errno.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>

#define PAM_SM_AUTH
#include <security/pam_modules.h>

#define PORT 			110
#define TIMEOUT 		30
#define OKSTR 			"+OK"
#define ERRSTR			"-ERR"
#define USERCMD 		"USER"
#define PASSCMD 		"PASS"
#define QUITCMD 		"QUIT"

static int debug = 0;
static int port = PORT;
static int timeout = TIMEOUT;
static char *hostname = NULL;
static char buf[1024];

static int get(int sockfd, char *desc)
{
    fd_set fdset;
    struct timeval tv;
    int numbytes = 0, ret = 0;

    FD_ZERO(&fdset);
    FD_SET(sockfd, &fdset);
    memset(buf, 0, sizeof(buf));

    tv.tv_sec = timeout;
    tv.tv_usec = 0;
    if ((ret = select(sockfd + 1, &fdset, NULL, NULL, &tv)) < 1) {
        if (ret == -1) {
            syslog(LOG_ERR, "Error while waiting for %s from server \'%s\' port %d: %m", desc, hostname, port);
        } else {
            syslog(LOG_ERR, "Timeout after %d seconds while waiting for %s from server \'%s\' port %d", timeout, desc,
                   hostname, port);
        }
        close(sockfd);
        return -1;
    }
    if ((numbytes = recv(sockfd, buf, sizeof(buf) - 1, MSG_NOSIGNAL)) <= 0) {
        if (numbytes == 0) {
            syslog(LOG_ERR, "Unexpected connection loss while reading %s from server \'%s\' port %d", desc, hostname, port);
            close(sockfd);
            return -1;
        } else {
            syslog(LOG_ERR, "Unexpected connection loss while reading %s from server \'%s\' port %d", desc, hostname, port);
            close(sockfd);
            return -1;
        }
    }
    if ((strstr(buf, OKSTR) == NULL) && (strstr(buf, ERRSTR) == NULL)) {
        syslog(LOG_ERR, "Could not interpret response \'%s\' for %s from server \'%s\' port %d", buf, desc, hostname, port);
        close(sockfd);
        return -1;
    }
    if (debug) {
        syslog(LOG_DEBUG, "Received %s: %s", desc, buf);
    }
    return (strstr(buf, OKSTR) != NULL) ? 1 : 0;
}

static int put(int sockfd, char *desc, char *cmd, char *arg)
{
    fd_set fdset;
    struct timeval tv;
    int numbytes = 0, ret;

    FD_ZERO(&fdset);
    FD_SET(sockfd, &fdset);
    snprintf(buf, sizeof(buf), "%s %s\r\n", cmd, arg);
    tv.tv_sec = timeout;
    tv.tv_usec = 0;
    if ((ret = select(sockfd + 1, NULL, &fdset, NULL, &tv)) < 1) {
        if (ret == -1) {
            syslog(LOG_ERR, "Error while waiting for %s write to server \'%s\' port %d: %m", desc, hostname, port);
        } else {
            syslog(LOG_ERR, "Timeout after %d seconds while waiting for %s write to server \'%s\' port %d", timeout, desc,
                   hostname, port);
        }
        close(sockfd);
        return -1;
    }
    if ((numbytes = send(sockfd, buf, strlen(buf), MSG_NOSIGNAL)) < strlen(buf)) {
        if (numbytes > 0) {
            tv.tv_sec = timeout;
            tv.tv_usec = 0;
            if ((ret = select(sockfd + 1, NULL, &fdset, NULL, &tv)) < 1) {
                if (ret == -1)
                    syslog(LOG_ERR, "Error while waiting for %s write to server \'%s\' port %d: %m", desc, hostname, port);
                else
                    syslog(LOG_ERR, "Timeout after %d seconds while waiting for %s write to server \'%s\' port %d", timeout,
                           desc, hostname, port);
                close(sockfd);
                return -1;
            }
            numbytes += send(sockfd, buf + numbytes, strlen(buf) - numbytes, MSG_NOSIGNAL);
        }
        if (numbytes != strlen(buf)) {
            syslog(LOG_ERR, "Error while writing %s to server \'%s\' port %d: %m", desc, hostname, port);
            close(sockfd);
            return -1;
        }
    }
    if (debug) {
        syslog(LOG_DEBUG, "Sent %s: %s", desc, buf);
    }
    return 0;
}

PAM_EXTERN int pam_sm_authenticate(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    int result = PAM_AUTH_ERR;
    int i, info = 0, sockfd, ret, use_first_pass = 0, try_first_pass = 0;
    struct hostent *he;
    struct sockaddr_in their_addr;
    char *val = 0, *username = NULL, *password = NULL, *pwprompt = "Password: ";

    i = LOG_CONS | LOG_PID | LOG_PERROR;
    openlog("PAM-pop3", i, LOG_AUTH);
    if (debug)
        syslog(LOG_DEBUG, "Starting module");

    for (i = 0; i < argc; i++) {
        if ((val = index(argv[i], '=')) == NULL) {
            if (strcmp(argv[i], "debug") == 0)
                debug = 1;
            else
            if (strcmp(argv[i], "info") == 0)
                info = 1;
            else
            if (strcmp(argv[i], "use_first_pass") == 0)
                use_first_pass = 1;
            else
            if (strcmp(argv[i], "try_first_pass") == 0)
                try_first_pass = 1;
            else
                syslog(LOG_ERR, "Unknown keyword found: %s", argv[i]);
            if (debug) {
                syslog(LOG_DEBUG, "Got Keyword \'%s\'", argv[i]);
            }
        } else {
            if (strlen(argv[i]) >= (sizeof(buf) - 1)) {
                syslog(LOG_ALERT, "Argument too long: %s", argv[i]);
                return result;
            }
            ret = strlen(argv[i]) - strlen(val);
            strncpy(buf, argv[i], ret);
            buf[ret] = 0;
            val++;
            if (debug) {
                syslog(LOG_DEBUG, "Got Paramter \'%s\' = \'%s\'", buf, val);
            }
            if (strcmp(buf, "hostname") == 0)
                hostname = val;
            else
            if (strcmp(buf, "port") == 0)
                port = atoi(val);
            else
            if (strcmp(buf, "timeout") == 0)
                timeout = atoi(val);
            else
            if (strcmp(buf, "username") == 0)
                username = val;
            else
            if (strcmp(buf, "password") == 0)
                password = val;
            else
            if (strcmp(buf, "pwprompt") == 0)
                pwprompt = val;
            else
                syslog(LOG_ERR, "Unknown keyword/value found: %s=%s", buf, val);
        }
    }
    if (username == NULL) {
        if (pam_get_user(pamh, (const char **) &username, NULL) != PAM_SUCCESS) {
            syslog(LOG_ERR, "Could not get username from libpam !");
            return result;
        }
        if (debug)
            syslog(LOG_DEBUG, "Set Username to: %s", username);
    }
    if (password == NULL) {
        if (pam_get_item(pamh, PAM_AUTHTOK, (const void **) &password) != PAM_SUCCESS) {
            if (use_first_pass == 1) {
                if (debug) {
                    syslog(LOG_DEBUG, "Authentication failed because I did not get a password from libpam and use_first_pass is set.");
                }
                return result;
            }
        }
    }
    if ((password == NULL) && (use_first_pass == 0)) {
        struct pam_conv *conv;
        struct pam_message msg[1], *pmsg[1];
        struct pam_response *resp;
        pmsg[0] = &msg[0];
        msg[0].msg_style = PAM_PROMPT_ECHO_OFF;
        msg[0].msg = pwprompt;

        if (pam_get_item(pamh, PAM_CONV, (const void **) &conv) == PAM_SUCCESS) {
            if (ret = conv->conv(1, (const struct pam_message **) pmsg, &resp, conv->appdata_ptr) == PAM_SUCCESS) {
                if (strlen(resp[0].resp) >= (sizeof(buf) - 1)) {
                    syslog(LOG_ERR, "Password given by user is too long !");
                    return result;
                }
                if (pam_set_item(pamh, PAM_AUTHTOK, resp[0].resp) != PAM_SUCCESS) {
                    syslog(LOG_ERR, "Can't set password in libpam !");
                    return result;
                }
                if (pam_get_item(pamh, PAM_AUTHTOK, (const void **) &password) != PAM_SUCCESS) {
                    if (use_first_pass == 1) {
                        if (debug) {
                            syslog(LOG_DEBUG, "Authentication failed because I did not get a password from libpam and use_first_pass is set.");
                        }
                        return result;
                    }
                }
            } else {
                syslog(LOG_ERR, "Could not converse with application !");
            }
        } else {
            syslog(LOG_ERR, "Could not get password conversion function from application.");
            return result;
        }
    }
    if ((hostname == NULL) || (username == NULL) || (password == NULL)) {
        if (debug) {
            syslog(LOG_ERR, "Not enough information. Need at least hostname, username and password !");
        }
        return result;
    }
    if ((he = gethostbyname(hostname)) == NULL) {
        syslog(LOG_ALERT, "Could not translate hostname \'%s\': %s", hostname, hstrerror(h_errno));
        return result;
    }

    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        syslog(LOG_ALERT, "Could not open a socket: %m");
        return result;
    }
    their_addr.sin_family = AF_INET;
    their_addr.sin_port = htons(port);
    their_addr.sin_addr = *((struct in_addr *) he->h_addr);
    memset(&(their_addr.sin_zero), 0, 8);

    if (connect(sockfd, (struct sockaddr *) &their_addr, sizeof(struct sockaddr)) == -1) {
        syslog(LOG_ERR, "Could not connect to server \'%s\' port %d: %m", hostname, port);
        close(sockfd);
        return result;
    }

    if (debug) {
        syslog(LOG_DEBUG, "Connected to server \'%s\' port %d", hostname, port);
    }
    switch (get(sockfd, "POP3 Greeting")) {
    case 1:
        break;
    case 0:
        syslog(LOG_ERR, "Got bad Greeting from server \'%s\' port %d: %m", hostname, port);
    default:
        return result;
    }
    if (put(sockfd, "Username", USERCMD, username) != 0) {
        return result;
    }
    switch (get(sockfd, "Username Response")) {
    case 1:
        break;
    case 0:
        syslog(LOG_ERR, "Got bad Username Response from server \'%s\' port %d: %m", hostname, port);
    default:
        return result;
    }
    if (put(sockfd, "Password", PASSCMD, password) != 0) {
        return result;
    }
    if ((i = get(sockfd, "Password Response")) == -1) {
        return result;
    }
    put(sockfd, "QUITting", QUITCMD, "");
    close(sockfd);
    if (debug || info) {
        if (i == 1)
            syslog(LOG_DEBUG, "Authentication Succeeded for %s at server %s port %d", username, hostname, port);
        else
            syslog(LOG_DEBUG, "Authentication Failed for %s at server %s port %d", username, hostname, port);
    }
    return (i == 1) ? PAM_SUCCESS : result;
}

PAM_EXTERN int pam_sm_setcred(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    return PAM_SUCCESS;
}

PAM_EXTERN pam_sm_acct_mgmt(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    return PAM_SUCCESS;
}


PAM_EXTERN pam_sm_open_session(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    return PAM_SUCCESS;
}

PAM_EXTERN pam_sm_close_session(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    return PAM_SUCCESS;
}

#ifdef PAM_STATIC
/* static module data */
struct pam_module _pam_pop3_modstruct = {
  "pam_pop3",
  pam_sm_authenticate,
  pam_sm_setcred,
  pam_sm_acct_mgmt,
  pam_sm_open_session,
  pam_sm_close_session,
  NULL,
};
#endif

#ifdef MAIN
int main(int argc, const char **argv)
{
    if (pam_sm_authenticate(NULL, 0, argc - 1, argv + 1) == PAM_SUCCESS)
        printf("Authentication succeeded\n");
    else
        printf("Authentication failed\n");
    return 0;
}
#endif
