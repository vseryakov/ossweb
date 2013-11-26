/* pam_ossweb module.
   Copyright (c) 2002 Vlad Seryakov(vlad@crystalballinc.com)
*/

#include <features.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <syslog.h>
#include <stdarg.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>
#include <netdb.h>
#include <errno.h>
#include <signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>

#define PAM_SM_AUTH

#include <security/pam_modules.h>
#include <security/_pam_macros.h>

static void _pam_log(int err, const char *format, ...)
{
    va_list args;

    va_start(args, format);
    openlog("PAM-ossweb", LOG_CONS | LOG_PID, LOG_AUTH);
    vsyslog(err, format, args);
    va_end(args);
    closelog();
}

static int is_ipaddr(const char *addr)
{
    int dot_count = 0, digit_count = 0;

    if (!addr)
        return (0);
    while (*addr && *addr != ' ') {
        if (*addr == '.') {
            dot_count++;
            digit_count = 0;
        } else if (!isdigit(*addr))
            dot_count = 5;
        else {
            digit_count++;
            if (digit_count > 3)
                dot_count = 5;
        }
        addr++;
    }
    if (dot_count == 3)
        return (1);
    return (0);
}

#ifndef HAVE_GETHOSTBYNAME_R
static pthread_mutex_t nss_lock = PTHREAD_MUTEX_INITIALIZER;
#endif

unsigned long safe_gethostbyname(const char *host)
{
    struct hostent *hp, hp_a, *hp_b;
    char buf[1024];
    int hp_errno;
    u_long ip;

    if (is_ipaddr(host))
        return inet_addr(host);
#if HAVE_GETHOSTBYNAME_R
#if defined(linux)
    if (!gethostbyname_r(host, &hp_a, buf, sizeof(buf), &hp_b, &hp_errno))
        hp = &hp_a;
    else
        hp = NULL;
#else
    hp = gethostbyname_r(host, &hp_a, buf, sizeof(buf), &hp_errno);
#endif
#else
    pthread_mutex_lock(&nss_lock);
    hp = gethostbyname(host);
#endif
    if (!hp) {
        _pam_log(LOG_ERR, "safe_gethostbyname: hostname '%s' not found", host);
#ifndef HAVE_GETHOSTBYNAME_R
        pthread_mutex_unlock(&nss_lock);
#endif
        return 0;
    }
#ifndef HAVE_GETHOSTBYNAME_R
    pthread_mutex_unlock(&nss_lock);
#endif
    return *((unsigned int *) hp->h_addr);
}

/*
 * This is a conversation function to obtain the user's password
 */
static int get_password(pam_handle_t * pamh, const char *message, const char **passwd)
{
    struct pam_message msg[2], *pmsg[2];
    struct pam_response *resp;
    const struct pam_conv *conv;

    pmsg[0] = &msg[0];
    msg[0].msg = message;
    msg[0].msg_style = PAM_PROMPT_ECHO_OFF;

    if (pam_get_item(pamh, PAM_CONV, (const void **) &conv) == PAM_SUCCESS &&
        conv->conv(1, (const struct pam_message **) &pmsg, &resp, conv->appdata_ptr) == PAM_SUCCESS && 
        resp != NULL) {
        *passwd = resp[0].resp;
        free(resp);
        return PAM_SUCCESS;
    }
    return PAM_SYSTEM_ERR;
}

static int ossweb_login(const char *host, int port, const char *user, const char *passwd)
{
    struct sockaddr_in remote;
    struct hostent *hp;
    char buf[512];
    int sock;
    fd_set fds;
    struct timeval t;

    _pam_log(LOG_DEBUG, "checking %s:%d for %s", host, port, user);
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        _pam_log(LOG_DEBUG, "socket: %s", strerror(errno));
        return PAM_SERVICE_ERR;
    }
    remote.sin_family = AF_INET;
    remote.sin_addr.s_addr = safe_gethostbyname(host);
    remote.sin_port = htons(port);
    if (connect(sock, (struct sockaddr *) &remote, sizeof(struct sockaddr_in)) < 0) {
        close(sock);
        _pam_log(LOG_DEBUG, "connect: %s", strerror(errno));
        return PAM_SERVICE_ERR;
    }
    snprintf(buf, sizeof(buf), "GET /ossweb/pub/verify.tcl?user_name=%s&password=%s HTTP/1.0\n\n", user, passwd);
    write(sock, buf, strlen(buf));
    t.tv_usec = 0;
    t.tv_sec = 5;
    FD_ZERO(&fds);
    FD_SET(sock, &fds);
    if (select(sock + 1, &fds, 0, 0, &t) == 1)
        read(sock, buf, sizeof(buf));
    close(sock);
    if (!strncmp(buf, "HTTP/1.0 200 OK", 15))
        return PAM_SUCCESS;
    return PAM_AUTH_ERR;
}

/* --- authentication management functions (only) --- */
PAM_EXTERN int pam_sm_authenticate(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    const char *user, *passwd, *host = "127.0.0.1";
    int i, retval, port = 8000;

    for (i = 0; i < argc; i++) {
        if (!strcmp(argv[i], "host"))
            host = argv[i];
        else if (!strcmp(argv[i], "port"))
            port = atoi(argv[i]);
    }
    if (pam_get_user(pamh, &user, NULL) != PAM_SUCCESS || !user) {
        _pam_log(LOG_DEBUG, "can not get the username");
        return PAM_SERVICE_ERR;
    }
    if (get_password(pamh, "Password:", &passwd) != PAM_SUCCESS) {
        _pam_log(LOG_DEBUG, "can not get the password");
        return PAM_SERVICE_ERR;
    }
    retval = ossweb_login(host, port, user, passwd);
    free((char *) passwd);
    _pam_log(LOG_DEBUG, "%s: authentication %s", user, retval == PAM_SUCCESS ? "OK" : "failed");
    return retval;
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
struct pam_module _pam_ossweb_modstruct = {
    "pam_ossweb",
    pam_sm_authenticate,
    pam_sm_setcred,
    pam_sm_acct_mgmt,
    pam_sm_open_session,
    pam_sm_close_session,
    NULL,
};
#endif

#ifdef MAIN
main(int argc, char **argv)
{
    printf("%d\n", ossweb_login(argv[1], argv[2], argv[3]));
}

#endif
