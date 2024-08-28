RSpec.describe "Organization management", type: :system, js: true do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:organization_admin) { create(:organization_admin, organization: organization) }
  let(:super_admin_org_admin) { create(:super_admin_org_admin, organization: organization) }

  include ActionView::RecordIdentifier

  shared_examples "organization role management checks" do |user_factory|
    let!(:managed_user) { create(user_factory, name: "User to be managed", organization: organization) }

    it 'can remove that user from the organization' do
      visit organization_path
      accept_confirm do
        click_button dom_id(managed_user, "dropdownMenu")
        click_link "Remove User"
      end

      expect(page).to have_content("User has been removed!")
      expect(managed_user.has_role?(Role::ORG_USER)).to be false
    end

    it "can promote that user from the organization" do
      visit organization_path
      accept_confirm do
        click_button dom_id(managed_user, "dropdownMenu")
        click_link "Promote to Admin"
      end

      expect(page).to have_content("User has been promoted!")
      expect(managed_user.has_role?(Role::ORG_ADMIN, organization)).to be true
    end

    it "can demote that user from the organization" do
      managed_user.add_role(Role::ORG_ADMIN, organization)
      visit organization_path
      accept_confirm do
        click_link "Demote to User"
      end

      expect(page).to have_content("User has been demoted!")
      expect(managed_user.has_role?(Role::ORG_ADMIN, organization)).to be false
    end
  end

  context "while signed in as an organization admin" do
    before do
      sign_in(organization_admin)
    end

    describe "Viewing the organization" do
      it "can view organization details", :aggregate_failures do
        organization.update!(one_step_partner_invite: true)

        visit organization_path

        expect(page.find("h1")).to have_text(organization.name)
        expect(page).to have_link("Home", href: dashboard_path)

        expect(page).to have_content("Organization Info")
        expect(page).to have_content("Contact Info")
        expect(page).to have_content("Default email text")
        expect(page).to have_content("Users")
        expect(page).to have_content("Short Name")
        expect(page).to have_content("URL")
        expect(page).to have_content("Partner Profile Sections")
        expect(page).to have_content("Custom Partner Invitation Message")
        expect(page).to have_content("Child Based Requests?")
        expect(page).to have_content("Individual Requests?")
        expect(page).to have_content("Quantity Based Requests?")
        expect(page).to have_content("Show Year-to-date values on distribution printout?")
        expect(page).to have_content("Logo")
        expect(page).to have_content("Use One step Partner invite and approve process?")
      end
    end

    describe "Editing the organization" do
      before do
        visit edit_organization_path
      end

      it "is prompted with placeholder text and a more helpful error message to ensure correct URL format as a user" do
        fill_in "Url", with: "www.diaperbase.com"
        click_on "Save"

        fill_in "Url", with: "http://www.diaperbase.com"
        click_on "Save"
        expect(page.find(".alert")).to have_content "pdated"
      end

      it "can set a reminder and a deadline day" do
        # TODO: change here
        fill_in "organization_every_n_months", with: 1
        choose 'toggle-to-week-day'
        select "First", from: "organization_every_nth_day"
        select "Friday", from: "organization_day_of_week"

        fill_in "organization_deadline_day", with: 16
        click_on "Save"
        expect(page.find(".alert")).to have_content "Updated"
        expect(page).to have_content("Monthly on the 1st Friday")
      end

      it 'can select if the org repackages essentials' do
        choose('organization[repackage_essentials]', option: true)

        click_on "Save"
        expect(page).to have_content("Yes")
      end

      it 'can select if the org distributes essentials monthly' do
        choose('organization[distribute_monthly]', option: true)

        click_on "Save"
        expect(page).to have_content("Yes")
      end

      it 'can select if the org shows year-to-date values on the distribution printout' do
        choose('organization[ytd_on_distribution_printout]', option: false)

        click_on "Save"
        expect(page).to have_content("No")
      end

      it 'can set a default storage location on the organization' do
        select(store.name, from: 'Default Storage Location')

        click_on "Save"
        expect(page).to have_content(store.name)
      end

      it 'can set the NDBN Member ID' do
        select(ndbn_member.full_name)

        click_on "Save"
        expect(page).to have_content(ndbn_member.full_name)
      end

      it 'can select and deselect Required Partner Fields' do
        # select first option in from Required Partner Fields
        select('Media Information', from: 'organization_partner_form_fields', visible: false)
        click_on "Save"
        expect(page).to have_content('Media Information')
        expect(organization.reload.partner_form_fields).to eq(['media_information'])
        # deselect previously chosen Required Partner Field
        click_on "Edit"
        unselect('Media Information', from: 'organization_partner_form_fields', visible: false)
        click_on "Save"
        expect(page).to_not have_content('Media Information')
        expect(organization.reload.partner_form_fields).to eq([])
      end

      it "can disable if the org does NOT use single step invite and approve partner process" do
        choose("organization[one_step_partner_invite]", option: false)

        click_on "Save"
        expect(page).to have_content("No")
      end

      it "can enable if the org uses single step invite and approve partner process" do
        choose("organization[one_step_partner_invite]", option: true)

        click_on "Save"
        expect(page).to have_content("Yes")
      end
    end

    it "can add a new user to an organization" do
      allow(User).to receive(:invite!).and_return(true)
      visit organization_path
      click_on "Invite User to this Organization"
      within "#addUserModal" do
        fill_in "email", with: "some_new_user@website.com"
        click_on "Invite User"
      end
      expect(page).to have_content("invited to organization")
    end

    context "managing a user from the organization" do
      include_examples "organization role management checks", :user
    end

    context "managing a super admin user from the organization" do
      include_examples "organization role management checks", :super_admin
    end
  end

  context "while signed in as a super admin" do
    before do
      sign_in(super_admin_org_admin)
    end

    before(:each) do
      visit admin_dashboard_path
      within ".main-header" do
        click_on super_admin_org_admin.name.to_s
      end
      click_link "Switch to: #{organization.name}"
    end

    context "managing a user from the organization" do
      include_examples "organization role management checks", :user
    end

    context "managing a super admin user from the organization" do
      include_examples "organization role management checks", :super_admin
    end
  end
end
