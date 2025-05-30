RSpec.describe "/partners/distributions", type: :request do
  let(:partner) { create(:partner) }
  let(:partner_user) { partner.primary_user }

  describe "GET #index" do
    subject { -> { get partners_distributions_path } }

    before do
      sign_in(partner_user)
    end

    it "should render without any issues" do
      subject.call
      expect(response).to render_template(:index)
    end

    it "should display the distribution's ID" do
      subject.call

      page = Nokogiri::HTML(response.body)
      header = page.css("table thead tr th")
      id_field_order = 1

      expect(header[id_field_order].text).to eq("ID")
    end
  end

  describe "GET #print" do
    before do
      sign_in(partner_user)
    end

    let(:distribution) { FactoryBot.create(:distribution, partner: partner) }
    it "returns http success" do
      get print_partners_distribution_path(distribution)
      expect(response).to be_successful
    end

    context "with non-UTF8 characters" do
      let(:non_utf8_partner) { create(:partner, name: "KOKA Keiki O Ka ‘Āina") }

      it "returns http success" do
        get print_partners_distribution_path(distribution)
        expect(response).to be_successful
      end
    end
  end
end
