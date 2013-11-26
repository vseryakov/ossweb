/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/


INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','users','view','unknown','Users List',
       'List of all users that have
       access to this Web system.<BR>Each user should be registered and have valid logn name and
       password. Also acces permissions should be defined in order to access various parts of
       application. By default user is included into public group which has access to public
       parts of the application. In order to be able to access admin pages, user should be
       included into admin group.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','users','edit','unknown','User Details',
       'This form defines users details.
       <B>User Name</B> is login name which should be entered in Login Box.<BR>
       <B>Email</B> is required because some applications use email notification and
       in this case this field will be used in order to send email to each particular user.<BR>
       Groups define access permissions, user can have more than one groups, so he will
       have access to all web pages that these groups allow.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','apps','view','unknown','Application List',
       'Applications page is used to
       define menu items to application pages.<BR>
       These menu items are located at the left side of each web page. Menu items can
       be grouped in logical folders. It is not necessary to define web page in Application
       in order to access this web page. It is used just for convenience and easy access to
       Web pages.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','apps','edit','unknown','Application Details',
       'Application Details form
       contains menu item information. <BR>
       Request information can be specified by standard request convention by using project,
       application context parameters or by specifying exact URL.<BR>
       <B>Image</B> is an icon that will used along with menu name, for folders there is
       predefined icon open.gif which will be replaced by closed.gif in case of folder is closed.<BR>
       In order to create new folder, neither application context nor URL should be specified.<BR>
       <B>Sort</B> field is used to manually sort menu items within group.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','config','view','unknown','Config Parameters',
       'This page allows specifying
       various configuration runtime parameters.<BR>
       These values will be read upon startup and used afterwards by applications.<P>
       Predefined parameters are:<P>
       <B>SessionTimeout</B> - defines expiration tinmeout for session cookies.<BR>
       <B>DefaultProject</B> - defines which project directory should be used in case of
       incomplete or invalid URL.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','msgs','view','unknown','System Messages',
       'System messages table contains
       global system wide messages that can be referred by name.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','groups','view','unknown','Group List',
       'Groups allow unite users in logical
       groups with the same access permissions. Once the group is setup and access permissions
       defined, users can be included in this group and they will inherit all
       group''s access rights. User can be included in more than one group, in this case
       he will have all combined access permissions from all groups.<P>
       Predefined groups are:<BR>
       <B>public</B> - access to all public web pages.<P>
       <B>admin</B> - access to everything including administration folder.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','groups','edit','unknown','Group Details',
       'Group Details form is used for
       entering or updating group information such as name or description or access permissions.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','acls','unknown','unknown','Access Permissions',
       E'The security filter will check
       access rights for application, context and command levels.
       Additional access restrictions may be applied inside application.
       The filter will check request line for valid
       application,application_context,command,command context tokens.
       To accomplish this we define that each request''s path name will consist 4 or 5 components:<BR>
       <I>/project_name/app_name/page_name.oss\\[?cmd=command\\[.command_context]]<BR>
       or<BR>
       /project_name/app_name/page_name.oss\\[?cmd=command]\\[&ctx=command_context]<BR>
       </I>
       where:<BR>
       <B> project_name</B>: is the directory, where all applications for this project are
       located.<P>
       <B>app_name</B>: is the directory where all pages for this application are located.
       Applications may be registered in the database. In this case, a security filter will
       refuse any requests with an invalid/unknown application.<P>
       <B>page_name</B>: is any application-specific meaningful part of the application logic.
       We can register all possible contexts within an application or allow the security
       administrator to enter any contexts in permission database.  In general, the application
       context is web page name, file name with html, or dynamic server parsed page.
       It can even be a virtual dynamic page whereby its contents are generated by the web server.<P>
       <B>cmd</B>: is an optional command within the current context. The commands should be
       defined and security filters will refuse requests with unknown commands.
       Commands may consist from two parts: the command name and command execution context.<P>
       <B>context</B>: defines an additional logic layer inside the current command operation.
       This is useful when complex application context have the same command for more than one
       object within this is context.  For example, the command ''Move'' may be applied to
       files, directories, documents, and urls within one repository context.<P>
       <B>ctx</B>: is command context in a different form as a query parameter.
       It is used for convenience because sometimes, for example, in submit buttons it is
       impossible to use names that look like ''update.order'' or ''update.account''.
       It is better to use command name as ''Update'' and set command context using hidden
       form field.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','admin','help.edit','unknown','unknown','Help Topics',
       'Each page may contain Help button or
       Help image which will invoke web page with help or description about this particular page.
       Help facility uses the same token as security handler to differentiate web pages.
       Because each web page has different project,application,context, command values,
       these values are used when help page is called. <BR>
       Administrator which has access to create help pages will have Edit link on help page.
       By clicking on that link system will call help creation page for the current web page.');

INSERT INTO ossweb_help (project_name,app_name,page_name,cmd_name,ctx_name,title,text)
       VALUES ('unknown','unknown','login','unknown','unknown','Login',
       'Enter user name and password and click on Login button');
