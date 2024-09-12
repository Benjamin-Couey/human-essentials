# [Super Admin] This is for administrating organizations at a global level. We can create, view, modify, etc.
class Admin::OrganizationsController < AdminController
  def edit
    @organization = Organization.find(params[:id])
    @organization.get_values_from_reminder_schedule
  end

  def update
    @organization = Organization.find(params[:id])
    if OrganizationUpdateService.update(@organization, organization_params)
      redirect_to admin_organizations_path, notice: "Updated organization!"
    else
      flash.now[:error] = @organization.errors.full_messages.join("\n")
      render :edit
    end
  end

  def index
    @filterrific = initialize_filterrific(
      Organization.alphabetized,
      params[:filterrific]
    ) || return

    @organizations = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @organization = Organization.new
    @organization.get_values_from_reminder_schedule
    account_request = params[:token] && AccountRequest.get_by_identity_token(params[:token])

    @user = User.new
    return unless account_request

    if account_request.processed?
      flash[:error] = "The account request had already been processed and cannot be used again"
    else
      @organization.assign_attributes_from_account_request(account_request)
      @user.assign_attributes(email: account_request.email, name: account_request.name)
    end
  end

  def create
    @user = User.new(user_params)

    @reminder_schedule = ReminderSchedule.new(reminder_schedule_params)
    @organization = Organization.new(organization_params)
    if @organization.save
      Organization.seed_items(@organization)
      UserInviteService.invite(name: user_params[:name],
                               email: user_params[:email],
                               roles: [Role::ORG_USER, Role::ORG_ADMIN],
                               resource: @organization)
      SnapshotEvent.publish(@organization) # need one to start with
      redirect_to admin_organizations_path, notice: "Organization added!"
    else
      flash.now[:error] = "Failed to create Organization."
      render :new
    end
  rescue => e
    flash.now[:error] = e
    render :new
  end

  def show
    @organization = Organization.find(params[:id])
    @header_link = admin_dashboard_path
    @default_storage_location = StorageLocation.find_by(id: @organization.default_storage_location) if @organization.default_storage_location
    @intake_storage_location = StorageLocation.find_by(id: @organization.storage_locations) if @organization.intake_location
    @users = @organization.users.with_discarded.includes(:roles, :organization).alphabetized
  end

  def destroy
    @organization = Organization.find(params[:id])
    if @organization.destroy
      redirect_to admin_organizations_path, notice: "Organization deleted!"
    else
      redirect_to admin_organizations_path, alert: "Failed to delete Organization."
    end
  end

  private

  def organization_params
    params.require(:organization)
          .permit(:name, :short_name, :street, :city, :state, :zipcode, :email, :url, :logo, :intake_location, :default_email_text, :account_request_id,
                  :every_n_months, :date_or_week_day, :date, :day_of_week, :every_nth_day, :deadline_day,
                  users_attributes: %i(name email organization_admin), account_request_attributes: %i(ndbn_member_id id))
  end

  def user_params
    params.require(:organization).require(:user).permit(:name, :email)
  end
end
