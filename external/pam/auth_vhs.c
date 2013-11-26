/*
 * Program:	Virtual user support for IMAP toolkit
 *              getpwnam is replaced with custom function
 *              which checks /etc/passwd or returns predefined
 *              passwd entry for virtual user. This is supposed to
 *              be used with PAM authentication, which will check supplied
 *              password.
 *
 * Author:	Vlad Seryakov
 *		Internet: vlad@crystalballinc.com
 *
 * Date:	4 March 2002
 * 
 * The IMAP toolkit provided in this Distribution is
 * Copyright 2001 University of Washington.
 * The full text of our legal notices is contained in the file called
 * CPYRIGHT, included with this Distribution.
 */

#include <grp.h>
#include <signal.h>
#include <sys/wait.h>
#include <stdio.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <ctype.h>
#include <errno.h>
#include <pwd.h>

#define IMAP_VHS_DIR "/usr/local/imap/spool"

static struct passwd pw_entry;
static char pw_buf[256];
static char pw_dir[256];

static struct passwd *getpw(char *name,uid_t uid) 
{
   char *p;
   FILE *fp = fopen("/etc/passwd","r");

   if(!fp) return 0;
   while(!feof(fp)) {
     if(!fgets(pw_buf,sizeof(pw_buf)-1,fp)) break;
     if(!(p = strchr(pw_buf,':'))) continue;
     *p++ = 0;
     if(!(p = strchr(p,':'))) continue;
     *p++ = 0;
     if((name && !strcmp(name,pw_buf)) || atoi(p) == uid) {
       pw_entry.pw_name = pw_buf;
       pw_entry.pw_passwd = "x";
       pw_entry.pw_uid = atoi(p);
       if(!(p = strchr(p,':'))) continue;
       pw_entry.pw_gid = atoi(++p);
       if(!(p = strchr(p,':'))) continue;
       *p++ = 0,pw_entry.pw_gecos = p;;
       if(!(p = strchr(p,':'))) continue;
       *p++ = 0,pw_entry.pw_dir = p;
       if(!(p = strchr(p,':'))) continue;
       *p++ = 0,pw_entry.pw_shell = p; 
       fclose(fp);
       return &pw_entry;
     }
   }
   fclose(fp);
   return 0;
}

struct passwd *getpwnam(const char * name)
{
   if(getpw(name,-1)) return &pw_entry;

   snprintf(pw_dir,sizeof(pw_dir)-1,"%s/%s",IMAP_VHS_DIR,name);
   pw_entry.pw_name = name;
   pw_entry.pw_passwd = "x";
   pw_entry.pw_uid = 99;
   pw_entry.pw_gid = 99;
   pw_entry.pw_gecos = name;
   pw_entry.pw_dir = pw_dir;
   pw_entry.pw_shell = "/bin/false";
   return &pw_entry;
}

struct passwd *getpwuid(uid_t uid)
{
   return getpw(0,uid);
}

