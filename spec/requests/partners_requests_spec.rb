RSpec.describe "Partners", type: :request do
  let(:organization) { create(:organization, partner_form_fields: ["media_information"]) }
  let(:user) { create(:user, organization: organization) }

  before do
    sign_in(user)
  end

  describe "GET #index" do
    subject do
      get partners_path(format: response_format)
      response
    end

    context "html" do
      let(:response_format) { 'html' }

      let!(:partner) { create(:partner, organization: organization) }

      it { is_expected.to be_successful }

      include_examples "restricts access to organization users/admins"
    end

    context "csv" do
      let(:response_format) { 'csv' }

      let!(:partner) do
        create(:partner, name:, email:, status: :approved, organization:, notes:, without_profile: true)
      end
      let!(:profile) do
        create(:partner_profile,
          partner: partner,
          address1: agency_address1,
          address2: agency_address2,
          city: agency_city,
          state: agency_state,
          zip_code: agency_zipcode,
          website: agency_website,
          agency_type: agency_type,
          other_agency_type: other_agency_type,
          primary_contact_name: contact_name,
          primary_contact_phone: contact_phone,
          primary_contact_mobile: contact_mobile,
          primary_contact_email: contact_email,
          agency_mission: agency_mission,
          enable_child_based_requests: enable_child_based_requests,
          enable_individual_requests: enable_individual_requests,
          enable_quantity_based_requests: enable_quantity_based_requests,
          program_address1: program_address1,
          program_address2: program_address2,
          program_city: program_city,
          program_state: program_state,
          program_zip_code: program_zip_code,
          facebook: facebook, #  Columns from the media_information partial
          twitter: twitter,
          instagram: instagram,
          no_social_media_presence: no_social_media_presence)
      end
      let(:name) { "Leslie Sue" }
      let(:email) { "leslie@sue.com" }
      let(:agency_address1) { "4744 McDermott Mountain" }
      let(:agency_address2) { "333 Never land street" }
      let(:agency_city) { "Lake Shoshana" }
      let(:agency_state) { "ND" }
      let(:agency_zipcode) { "09980-7010" }
      let(:agency_website) { "bosco.example" }
      let(:agency_type) { :other }
      let(:other_agency_type) { "Another Agency Name" }
      let(:contact_name) { "Jon Ralfeo" }
      let(:contact_phone) { "1231231234" }
      let(:contact_mobile) { "4564564567" }
      let(:contact_email) { "jon@entertainment720.com" }
      let(:notes) { "Some notes" }
      let(:providing_diapers) { {value: "N", index: 22} }
      let(:providing_period_supplies) { {value: "N", index: 23} }
      let(:agency_mission) { "agency_mission" }
      let(:enable_child_based_requests) { true }
      let(:enable_individual_requests) { true }
      let(:enable_quantity_based_requests) { true }
      let(:program_address1) { "program_address1" }
      let(:program_address2) { "program_address2" }
      let(:program_city) { "program_city" }
      let(:program_state) { "program_state" }
      let(:program_zip_code) { 12345 }
      let(:facebook) { "facebook" } # Columns from the media_information partial
      let(:twitter) { "twitter" }
      let(:instagram) { "instagram" }
      let(:no_social_media_presence) { false }

      let(:expected_headers) {
        [
          "Agency Name",
          "Agency Email",
          "Agency Address",
          "Agency City",
          "Agency State",
          "Agency Zip Code",
          "Agency Website",
          "Agency Type",
          "Contact Name",
          "Contact Phone",
          "Contact Cell",
          "Contact Email",
          "Agency Mission",
          "Child-based Requests",
          "Individual Requests",
          "Quantity-based Requests",
          "Program/Delivery Address",
          "Program City",
          "Program State",
          "Program Zip Code",
          "Notes",
          "Counties Served",
          "Providing Diapers",
          "Providing Period Supplies",
          "Facebook", # Columns from the media_information partial
          "Twitter",
          "Instagram",
          "No Social Media Presence"
        ]
      }

      let(:expected_values) {
        [
          partner.name,
          partner.email,
          "#{agency_address1}, #{agency_address2}",
          agency_city,
          agency_state,
          agency_zipcode,
          agency_website,
          "#{I18n.t "partners_profile.other"}: #{other_agency_type}",
          contact_name,
          contact_phone,
          contact_mobile,
          contact_email,
          agency_mission,
          enable_child_based_requests.to_s,
          enable_individual_requests.to_s,
          enable_quantity_based_requests.to_s,
          "#{program_address1}, #{program_address2}",
          program_city,
          program_state,
          program_zip_code.to_s,
          notes,
          "", # no counties
          providing_diapers[:value],
          providing_period_supplies[:value],
          facebook, # Columns from the media_information partial
          twitter,
          instagram,
          no_social_media_presence.to_s
        ]
      }

      it { is_expected.to be_successful }
      it "returns the expected headers" do
        get partners_path(partner, format: response_format)

        csv = CSV.parse(response.body)

        expect(csv[0]).to eq(expected_headers)
      end

      context "with missing partner info" do
        it "returns a CSV with correct data" do
          partner.update(profile: create(
            :partner_profile,
            website: nil,
            primary_contact_name: nil,
            primary_contact_email: nil
          ))

          expected_values = [
            partner.name,
            partner.email,
            ", ",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            enable_child_based_requests.to_s,
            enable_individual_requests.to_s,
            enable_quantity_based_requests.to_s,
            ", ",
            "",
            "",
            "",
            notes,
            "",
            providing_diapers[:value],
            providing_period_supplies[:value],
            "", # Columns from the media_information partial
            "",
            "",
            ""
          ]

          get partners_path(partner, format: response_format)
          csv = CSV.parse(response.body)
          expect(csv[1]).to eq(expected_values)
        end
      end

      it "returns a CSV with correct data" do
        get partners_path(partner, format: response_format)

        csv = CSV.parse(response.body)

        expect(csv[1]).to eq(expected_values)
      end

      it "returns only active partners by default" do
        partner.update(status: :deactivated)

        get partners_path(partner, format: response_format)
        csv = CSV.parse(response.body)
        # Expect no parner rows in csv
        expect(csv[0]).to eq(expected_headers)
        expect(csv[1]).to eq(nil)
      end

      context "with served counties" do
        it "returns them in correct order" do
          county_1 = create(:county, name: "High County, Maine", region: "Maine")
          county_2 = create(:county, name: "laRue County, Louisiana", region: "Louisiana")
          county_3 = create(:county, name: "Ste. Anne County, Louisiana", region: "Louisiana")
          create(:partners_served_area, partner_profile: profile, county: county_1, client_share: 50)
          create(:partners_served_area, partner_profile: profile, county: county_2, client_share: 40)
          create(:partners_served_area, partner_profile: profile, county: county_3, client_share: 10)

          get partners_path(partner, format: response_format)

          csv = CSV.parse(response.body, headers: true)

          expect(csv[0]["Counties Served"]).to eq("laRue County, Louisiana; Ste. Anne County, Louisiana; High County, Maine")
        end
      end

      context "with multiple partners do" do
        let!(:partner_2) do
          create(:partner, name: name_2, email: email_2, status: :invited, organization:, notes: notes_2, without_profile: true)
        end
        let!(:profile_2) do
          create(:partner_profile,
            partner: partner_2,
            address1: agency_address1_2,
            address2: agency_address2_2,
            city: agency_city_2,
            state: agency_state_2,
            zip_code: agency_zipcode_2,
            website: agency_website_2,
            agency_type: agency_type_2,
            other_agency_type: other_agency_type_2,
            primary_contact_name: contact_name_2,
            primary_contact_phone: contact_phone_2,
            primary_contact_mobile: contact_mobile_2,
            primary_contact_email: contact_email_2,
            agency_mission: agency_mission_2,
            enable_child_based_requests: enable_child_based_requests_2,
            enable_individual_requests: enable_individual_requests_2,
            enable_quantity_based_requests: enable_quantity_based_requests_2,
            program_address1: program_address1_2,
            program_address2: program_address2_2,
            program_city: program_city_2,
            program_state: program_state_2,
            program_zip_code: program_zip_code_2,
            facebook: facebook_2, #  Columns from the media_information partial
            twitter: twitter_2,
            instagram: instagram_2,
            no_social_media_presence: no_social_media_presence_2)
        end

        let(:name_2) { "Jane Doe" }
        let(:email_2) { "jane@doe.com" }
        let(:agency_address1_2) { "123 Main St" }
        let(:agency_address2_2) { "C.O. box 678" }
        let(:agency_city_2) { "Paris" }
        let(:agency_state_2) { "TX" }
        let(:agency_zipcode_2) { "30234-0000" }
        let(:agency_website_2) { "human.example" }
        let(:agency_type_2) { :other }
        let(:other_agency_type_2) { "Another Agency Name" }
        let(:contact_name_2) { "Fakey McFakePerson" }
        let(:contact_phone_2) { "1234567890" }
        let(:contact_mobile_2) { "1234567890" }
        let(:contact_email_2) { "fakey@gmail.com" }
        let(:notes_2) { "Some notes 2" }
        let(:providing_diapers_2) { {value: "N", index: 22} }
        let(:providing_period_supplies_2) { {value: "N", index: 23} }
        let(:agency_mission_2) { "agency_mission" }
        let(:enable_child_based_requests_2) { true }
        let(:enable_individual_requests_2) { true }
        let(:enable_quantity_based_requests_2) { true }
        let(:program_address1_2) { "program_address1" }
        let(:program_address2_2) { "program_address2" }
        let(:program_city_2) { "program_city" }
        let(:program_state_2) { "program_state" }
        let(:program_zip_code_2) { 12345 }
        let(:facebook_2) { "facebook" } # Columns from the media_information partial
        let(:twitter_2) { "twitter" }
        let(:instagram_2) { "instagram" }
        let(:no_social_media_presence_2) { false }

        it "orders partners alphaetically" do
          get partners_path(partner, format: response_format)

          csv = CSV.parse(response.body)

          expect(csv[1]).to eq(
            [
              partner_2.name,
              partner_2.email,
              "#{agency_address1_2}, #{agency_address2_2}",
              agency_city_2,
              agency_state_2,
              agency_zipcode_2,
              agency_website_2,
              "#{I18n.t "partners_profile.other"}: #{other_agency_type_2}",
              contact_name_2,
              contact_phone_2,
              contact_mobile_2,
              contact_email_2,
              agency_mission_2,
              enable_child_based_requests_2.to_s,
              enable_individual_requests_2.to_s,
              enable_quantity_based_requests_2.to_s,
              "#{program_address1_2}, #{program_address2_2}",
              program_city_2,
              program_state_2,
              program_zip_code_2.to_s,
              notes_2,
              "", # no counties
              providing_diapers_2[:value],
              providing_period_supplies_2[:value],
              facebook_2, # Columns from the media_information partial
              twitter_2,
              instagram_2,
              no_social_media_presence_2.to_s
            ]
          )
        end
      end
    end
  end

  describe 'POST #create' do
    subject { -> { post partners_path(partner_attrs) } }

    context 'when given valid partner attributes in the params' do
      let(:partner_attrs) do
        {
          partner: FactoryBot.attributes_for(:partner)
        }
      end

      it 'should create a new Partner record' do
        expect { subject.call }.to change { Partner.all.count }.by(1)
      end

      it 'should create a new Partners::Profile record' do
        expect { subject.call }.to change { Partners::Profile.all.count }.by(1)
      end

      it 'redirect to the partners index page' do
        subject.call
        expect(response).to redirect_to(partners_path)
      end
    end

    context 'when given invalid partner attributes in the params' do
      let(:partner_attrs) do
        {
          partner: {
            name: nil
          }
        }
      end

      it 'should not create a new Partner record' do
        expect { subject.call }.not_to change { Partner.all.count }
      end

      it 'should not create a new Partners::Profile record' do
        expect { subject.call }.not_to change { Partners::Profile.all.count }
      end

      it 'should display the error message' do
        subject.call
        expect(response.body).to include("Failed to add partner due to: ")
      end
    end
  end

  describe "GET #show" do
    subject do
      get partner_path(partner, format: response_format)
      response
    end

    let(:partner) do
      partner = create(:partner, organization: organization, status: :approved)
      partner.distributions << create(:distribution, :with_items, :past, item_quantity: 1231)
      partner
    end
    let!(:family1) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-123', partner: partner) }
    let!(:family2) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-126', partner: partner) }
    let!(:family3) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-123', partner: partner) }

    let!(:child1) { FactoryBot.create_list(:partners_child, 2, family: family1) }
    let!(:child2) { FactoryBot.create_list(:partners_child, 2, family: family3) }

    let(:expected_impact_metrics) do
      {
        families_served: 3,
        children_served: 4,
        family_zipcodes: 2,
        family_zipcodes_list: contain_exactly("45612-126", "45612-123") # order of zipcodes not guaranteed
      }
    end

    context "html" do
      let(:response_format) { 'html' }

      it "displays distribution scheduled date" do
        subject
        partner.distributions.each do |distribution|
          expect(subject.body).to include(distribution.issued_at.strftime("%m/%d/%Y"))
          expect(subject.body).to_not include(distribution.created_at.strftime("%m/%d/%Y"))
        end
      end

      context "without org admin" do
        it 'should not show the manage users button' do
          expect(subject).to be_successful
          expect(subject.body).not_to include("Manage Users")
        end
      end

      context "with org admin" do
        before(:each) do
          user.add_role(Role::ORG_ADMIN, organization)
        end
        it 'should show the manage users button' do
          expect(subject).to be_successful
          expect(subject.body).to include("Manage Users")
        end
      end

      context "when the partner is invited" do
        it "includes impact metrics" do
          subject
          expect(assigns[:impact_metrics]).to match(expected_impact_metrics)
        end
      end

      context "when the partner is uninvited" do
        let(:partner) { create(:partner, organization: organization, status: :uninvited) }

        it "does not include impact metrics" do
          subject
          expect(assigns[:impact_metrics]).not_to be_present
        end

        it 'does not show the delete button' do
          expect(subject).not_to include('Delete')
        end

        context 'when the partner has no users' do
          # see the deletable? method which is tested separately in the partner model spec
          it 'shows the delete button' do
            partner.users.each(&:destroy)
            expect(subject.body).to include('Delete')
          end
        end
      end
    end

    context "csv" do
      let(:response_format) { 'csv' }

      it { is_expected.to be_successful }
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get new_partner_path
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns http success" do
      get edit_partner_path(id: create(:partner, organization: organization))
      expect(response).to be_successful
    end
  end

  describe "POST #import_csv" do
    let(:model_class) { Partner }

    context "with a csv file" do
      let(:file) { fixture_file_upload("#{model_class.name.underscore.pluralize}.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message" do
        subject
        expect(response).to have_notice "#{model_class.name.underscore.humanize.pluralize} were imported successfully!"
      end
    end

    context "without a csv file" do
      it "redirects to :index" do
        post import_csv_partners_path
        expect(response).to be_redirect
      end

      it "presents a flash error message" do
        post import_csv_partners_path
        expect(response).to have_error "No file was attached!"
      end
    end

    context "csv file with wrong headers" do
      let(:file) { fixture_file_upload("wrong_headers.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash error message" do
        subject
        expect(response).to have_error "Check headers in file!"
      end
    end

    context "csv file with invalid email address" do
      let(:file) { fixture_file_upload("partners_with_invalid_email.csv", "text/csv") }
      subject { post import_csv_partners_path, params: { file: file } }

      it "invokes .import_csv" do
        expect(model_class).to respond_to(:import_csv).with(2).arguments
      end

      it "redirects to :index" do
        subject
        expect(response).to be_redirect
      end

      it "presents a flash notice message displaying the import errors" do
        subject
        expect(response).to have_error(/The following #{model_class.name.underscore.humanize.pluralize} did not import successfully:/)
        expect(response).to have_error(/Partner 2: Email is invalid/)
      end
    end
  end

  describe "POST #create" do
    context "successful save" do
      partner_params = { partner: { name: "A Partner", email: "partner@example.com", send_reminders: "false" } }

      it "creates a new partner" do
        post partners_path(partner_params)
        expect(response).to have_http_status(:found)
      end

      it "redirects to #index" do
        post partners_path(partner_params)
        expect(response).to redirect_to(partners_path)
      end
    end

    context "unsuccessful save due to empty params" do
      partner_params = { partner: { name: "", email: "" } }

      it "renders :new" do
        post partners_path(partner_params)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "POST #update" do
    context "successful save" do
      partner_params = { name: "A Partner", email: "partner@example.com", send_reminders: "false" }

      it "update partner" do
        partner = create(:partner, organization: organization)
        put partner_path(id: partner, partner: partner_params)
        expect(response).to have_http_status(:found)
      end

      it "redirects to #show" do
        partner = create(:partner, organization: organization)
        put partner_path(id: partner, partner: partner_params)
        expect(response).to redirect_to(partner_path(partner))
      end
    end

    context "unsuccessful save due to empty params" do
      partner_params = { name: "", email: "" }

      it "renders :edit" do
        partner = create(:partner, organization: organization)
        put partner_path(id: partner, partner: partner_params)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    it "redirects to #index" do
      delete partner_path(id: create(:partner, organization: organization))
      expect(response).to redirect_to(partners_path)
    end
  end

  describe "POST #invite" do
    let(:partner) { create(:partner, organization: organization) }
    before do
      service = instance_double(PartnerInviteService, call: nil, errors: [])
      allow(PartnerInviteService).to receive(:new).and_return(service)
    end

    it "sends the invite" do
      post invite_partner_path(id: partner.id)
      expect(PartnerInviteService).to have_received(:new).with(partner: partner, force: true)
      expect(response).to have_http_status(:found)
    end
  end

  describe "PUT #deactivate" do
    let(:partner) { create(:partner, organization: organization, status: "approved") }

    context "when the partner successfully deactivates" do
      it "changes the partner status to deactivated and redirects with flash" do
        put deactivate_partner_path(id: partner.id)

        expect(partner.reload.status).to eq("deactivated")
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully deactivated!")
      end
    end
  end

  describe "GET #approve_application" do
    subject { -> { get approve_application_partner_path(id: partner.id) } }
    let(:partner) { create(:partner, organization: organization) }
    let(:fake_partner_approval_service) { instance_double(PartnerApprovalService, call: -> {}) }

    before do
      allow(PartnerApprovalService).to receive(:new).with(partner: partner).and_return(fake_partner_approval_service)
    end

    context 'when the approval was successful' do
      before do
        allow(fake_partner_approval_service).to receive(:errors).and_return([])
        subject.call
      end

      it 'should redirect to the partners index page with a success flash message' do
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("Partner approved!")
      end
    end

    context 'when the approval failed' do
      let(:fake_error_msg) { Faker::Games::ElderScrolls.dragon }
      before do
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :none?).and_return(false)
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :full_messages).and_return(fake_error_msg)
        subject.call
      end

      it 'should redirect to the partners index page with a failure flash message' do
        expect(response).to redirect_to(partners_path)
        expect(flash[:error]).to eq("Failed to approve partner because: #{fake_error_msg}")
      end
    end
  end

  describe "PUT #reactivate" do
    context "when the partner successfully reactivates" do
      let(:partner) { create(:partner, organization: organization, status: "deactivated") }

      it "changes the partner status to approved and redirects with flash" do
        put reactivate_partner_path(id: partner.id)

        expect(partner.reload.status).to eq('approved')
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("#{partner.name} successfully reactivated!")
      end
    end

    context "when trying to reactivate a partner who is not deactivated " do
      let(:partner) { create(:partner, organization: organization, status: "approved") }
      it "fails to change the partner status to reactivated and redirects with flash error message" do
        put reactivate_partner_path(id: partner.id)
      end
    end
  end

  describe "POST #recertify_partner" do
    subject { -> { post recertify_partner_partner_path(id: partner.id) } }
    let(:partner) { create(:partner, organization: organization) }
    let(:fake_service) { instance_double(PartnerRequestRecertificationService, call: -> {}) }

    before do
      allow(PartnerRequestRecertificationService).to receive(:new).with(partner: partner).and_return(fake_service)
    end

    context "when the request for recertification from the partner was successful" do
      before do
        allow(fake_service).to receive_message_chain(:errors, :none?).and_return(true)
      end

      it 'should return back to the partners page with a success flash' do
        subject.call
        expect(flash[:success]).to eq("#{partner.name} recertification successfully requested!")
        expect(response).to redirect_to(partners_path)
      end
    end

    context "when the request for recertification from the partner was NOT successful" do
      before do
        allow(fake_service).to receive_message_chain(:errors, :none?).and_return(false)
      end

      it 'should return back to the partners page with a success flash' do
        subject.call
        expect(flash[:error]).to eq("#{partner.name} failed to update partner records")
        expect(response).to redirect_to(partners_path)
      end
    end
  end

  describe "POST #invite_and_approve" do
    let(:partner) { create(:partner, organization: organization) }

    context "when invitation succeeded and approval succeed" do
      before do
        fake_partner_invite_service = instance_double(PartnerInviteService, call: nil, errors: [])
        allow(PartnerInviteService).to receive(:new).and_return(fake_partner_invite_service)

        fake_partner_approval_service = instance_double(PartnerApprovalService, call: nil, errors: [])
        allow(PartnerApprovalService).to receive(:new).with(partner: partner).and_return(fake_partner_approval_service)
      end

      it "sends invitation email and approve partner in single step" do
        post invite_and_approve_partner_path(id: partner.id)

        expect(PartnerInviteService).to have_received(:new).with(partner: partner, force: true)
        expect(response).to have_http_status(:found)

        expect(PartnerApprovalService).to have_received(:new).with(partner: partner)
        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("Partner invited and approved!")
      end
    end

    context "when invitation failed" do
      let(:fake_error_msg) { Faker::Games::ElderScrolls.dragon }

      before do
        fake_partner_invite_service = instance_double(PartnerInviteService, call: nil)
        allow(PartnerInviteService).to receive(:new).with(partner: partner, force: true).and_return(fake_partner_invite_service)
        allow(fake_partner_invite_service).to receive_message_chain(:errors, :none?).and_return(false)
        allow(fake_partner_invite_service).to receive_message_chain(:errors, :full_messages).and_return(fake_error_msg)
      end

      it "should redirect to the partners index page with a notice flash message" do
        post invite_and_approve_partner_path(id: partner.id)

        expect(response).to redirect_to(partners_path)
        expect(flash[:notice]).to eq("Failed to invite #{partner.name}! #{fake_error_msg}")
      end
    end

    context "when approval fails" do
      let(:fake_error_msg) { Faker::Games::ElderScrolls.dragon }

      before do
        fake_partner_approval_service = instance_double(PartnerApprovalService, call: nil)
        allow(PartnerApprovalService).to receive(:new).with(partner: partner).and_return(fake_partner_approval_service)
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :none?).and_return(false)
        allow(fake_partner_approval_service).to receive_message_chain(:errors, :full_messages).and_return(fake_error_msg)
      end

      it "should redirect to the partners index page with a notice flash message" do
        post invite_and_approve_partner_path(id: partner.id)

        expect(response).to redirect_to(partners_path)
        expect(flash[:error]).to eq("Failed to approve partner because: #{fake_error_msg}")
      end
    end
  end
end
