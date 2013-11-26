Subject: Maverix Anti-Spam Message
From: @maverix_email@
To: @sender_email@
Errors-To: @maverix_email@
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="@boundary@"

<if 0 eq 1>
--@boundary@
Content-Type: text/plain

You have recently sent an email message to address specified below.
In order to have your message delivered, click on link in brackets
after each email address:

<multirow name=messages>
@messages.user_email@ [@messages.sender_verify@]
</multirow>

Once you have verified, your E-mail will be allowed to pass
through and you will be put on list of verified addresses and you will
not have to go through this process again.

--
Maverix Systems
http://www.maverixsystems.com
What's this: http://www.maverixsystems.com/maverixuserguide.htm
</if>

--@boundary@
Content-Type: text/html

<BODY BGCOLOR=white STYLE="color:black">
You have recently sent an email message to address specified below.
In order to have your message delivered, click on <B>Verify</B> link
after each email address:

<UL>
<multirow name=messages>
<LI>@messages.user_email@ <A HREF=@messages.sender_verify@ TARGET=Mvrx>Verify</A>
</multirow>
</UL>

<P>
 
Once you have verified, your E-mail will be allowed to pass
through and you will be put on list of verified addresses and you will
not have to go through this process again.
<P>

--<BR>
<A HREF=http://www.maverixsystems.com/maverixuserguide.htm#_Toc39487182>What's this?</A>
<P>
Maverix Systems<BR>
http://www.maverixsystems.com<BR>
</BODY>

--@boundary@--
