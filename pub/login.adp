<master src="index">

<CENTER>
<TABLE BORDER=0 WIDTH=400>
<TR><TD><formtemplate id=form_login></formtemplate></TD></TR>
</TABLE>
</CENTER>

<SCRIPT LANGUAGE=JavaScript>

function doLogin()
{
  var form = document.form_login;
  if(!form.encrypted || form.encrypted.checked) {
    form.password.value = calcSHA1(form.password.value+form.user_name.value).toUpperCase();
    form.password.value = calcSHA1(form.password.value+'<%=[ossweb::conn peeraddr]%>').toUpperCase();
  }
  form.submit();
  return true;
}
document.form_login.user_name.focus();
</SCRIPT>
