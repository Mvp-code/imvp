		<%if(submitType == SubmitType.BROWSE) {
			if(_recordBean.getCreateUser().length() == 0) { _recordBean.setCreateUser("testUser"); }
			String auditCreatedBy = "<B>Created by : </B>"+_recordBean.getCreateUser()+" on "+_recordBean.getCreateDate();
			String auditUpdatedBy = "";
			if(_recordBean.getUpdateDate().length() > 0) {
				if(_recordBean.getUpdateUser().length() == 0) { _recordBean.setUpdateUser("testUser"); }
				if("2".equalsIgnoreCase(_recordBean.getStatus()))
					auditUpdatedBy = "<B>Posted by : </B>"+_recordBean.getUpdateUser()+" on "+_recordBean.getUpdateDate();
				else
					auditUpdatedBy = "<B>Updated by : </B>"+_recordBean.getUpdateUser()+" on "+_recordBean.getUpdateDate();
			}
			%>
			<div class="row col-12 pt-3">
				<div class="col-12 col-md-6"><%=auditCreatedBy%></div>
				<div class="col-12 col-md-6"><%=auditUpdatedBy%></div>
			</div>
		<%}%>

<%
String shellNoFormFooter = request.getAttribute("shellNoForm") == null ? "" : request.getAttribute("shellNoForm").toString().trim();
if(!"yes".equalsIgnoreCase(shellNoFormFooter)) {
%>
		</form>
<%}%>

	</div><!-- /mvpx-body -->
<%if(!"yes".equalsIgnoreCase(isPopup)) {%>
</div><!-- /mvpx-main -->
</div><!-- /mvpx-shell -->
<%} else {%>
</div><!-- /popup-wrap -->
<%}%>
</body>
</html>
