<!DOCTYPE html>
<html lang="en">
<%@ page import="java.util.*, com.util.*"%>
<jsp:useBean id="_errorBean" class="com.beans.ErrorBean" scope="request" />
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Login - MVPG</title>
<style>
	:root {
		--primary-color: #2563eb;
		--error-color: #C62828;
		--success-color: #15803D;
		--warn-color: #B45309;
		--accent-color: #1D4ED8;
		--background-color: #f9fafb;
		--card-color: #ffffff;
		--text-dark: #1f2937;
		--text-muted: #6b7280;
		--status-ok-fg: #15803D; --status-ok-bg: #E7F6EE; --status-ok-border: #CDEBD9;
		--status-warn-fg: #B45309; --status-warn-bg: #FBF1E2; --status-warn-border: #F3E3C8;
		--status-action-fg: #C62828; --status-action-bg: #FCEBEB; --status-action-border: #F3C1C1;
		--status-escalation-fg: #991B1B; --status-escalation-bg: #FEE2E2; --status-escalation-border: #FCA5A5;
		--status-info-fg: #1D4ED8; --status-info-bg: #EFF4FF; --status-info-border: #DBE6FF;
	}
	* {
		box-sizing: border-box;
	}
	body {
		margin: 0;
		font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
		background: var(--background-color);
		display: flex;
		justify-content: center;
		align-items: center;
		height: 100vh;
	}

	.login-card {
		background: var(--card-color);
		padding: 2rem;
		border-radius: 12px;
		box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
		max-width: 400px;
		width: 100%;
	}
	.login-card h2 {
		text-align: center;
		color: var(--primary-color);
		margin-bottom: 1.5rem;
	}

	.form-group {
		margin-bottom: 1rem;
	}
	.form-group label {
		display: block;
		margin-bottom: 0.5rem;
		color: var(--text-dark);
	}
	.form-group input {
		width: 100%;
		padding: 0.75rem;
		border: 1px solid #d1d5db;
		border-radius: 8px;
		font-size: 1rem;
	}

	.message {
		text-align: center;
		font-size: 0.95rem;
		margin-bottom: 1rem;
		padding: 0.75rem;
		border-radius: 8px;
	}
	.success-message {
		background-color: var(--status-ok-bg);
		color: var(--status-ok-fg);
		border: 1px solid var(--status-ok-border);
	}
	.error-message {
		background-color: var(--status-escalation-bg);
		color: var(--status-escalation-fg);
		border: 1px solid var(--status-escalation-border);
	}
	.warning-message {
		background-color: var(--status-warn-bg);
		color: var(--status-warn-fg);
		border: 1px solid var(--status-warn-border);
	}
	.notice-message {
		background-color: var(--status-info-bg);
		color: var(--status-info-fg);
		border: 1px solid var(--status-info-border);
	}

	.login-btn {
		width: 100%;
		padding: 0.75rem;
		background: var(--primary-color);
		color: white;
		border: none;
		border-radius: 8px;
		font-size: 1rem;
		cursor: pointer;
		transition: background 0.3s ease;
	}
	.login-btn:hover {
		background: var(--accent-color);
	}

	input:required:invalid {
		border: 2px solid #ef4444; /* Tailwind's red-500 */
		/*background-color: #fff0f0;*/
	}
	input:required:valid {
		border: 2px solid #22c55e; /* green-500 (optional success) */
	}

	.footer {
		margin-top: 1rem;
		text-align: center;
		font-size: 0.9rem;
		color: var(--text-muted);
	}

	@media (max-width: 480px) {
		.login-card {
			margin: 1rem;
			padding: 1.5rem;
		}

		.login-card h2 {
			font-size: 1.5rem;
		}
	}
</style>
</head>
<body>
<div class="login-card">
	<h2>MVPG Login</h2>
	<%if(_errorBean != null && _errorBean.getType().length() > 0) {%><div class="message <%=_errorBean.getType()%>-message"><%=_errorBean.getMesg()%></div><%}%>
	<form  name="formmain" method="post" onsubmit="return handleLogin(event)">
		<div class="form-group">
			<label for="loginUser">User</label>
			<input type="text" id="loginUser" name="loginUser" required />
		</div>
		<div class="form-group">
			<label for="loginPwd">Password</label>
			<input type="password" id="loginPwd" name="loginPwd" required />
		</div>
		<button type="submit" class="login-btn">Login</button>
	</form>
	<div class="footer">MVP Logistics Dispatch Portal</div>
</div>

<script>
function validateEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}

document.getElementById("loginPwd").addEventListener("focus", function () {
    const user = document.getElementById("loginUser").value;
    if (user.trim() !== "") {
		if(!isNaN(user)) {
			// Username is numeric
			this.value = user;
			document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.LOGIN%>&controller=Login";
			document.formmain.submit();
		} else if(validateEmail(user)) {
			// Username is email
			this.value = user;
			document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.LOGIN%>&controller=Login";
			document.formmain.submit();
		}
    } else {
        // Username is not numeric
        this.value = "";
    }
});

function handleLogin(e) {
	e.preventDefault();
	document.formmain.action = "../servlet/MVPGServlet?submitType=<%=SubmitType.LOGIN%>&controller=Login";
	document.formmain.submit();
	return false;
}
document.formmain["loginUser"].focus();
</script>
</body>
</html>