require 'rails_helper'

describe User, :type => :model do

  it { should have_one :profile }
  it { should validate_uniqueness_of :uid }

  # This fails due to the implementation of shoulda-matchers.
  # But: does this show up a problem in how we're generating UIDs? -- Yoz
  # it { should validate_presence_of :uid }


  describe "#create" do
    before do
      @valid_attributes = {
        :email => 'joe@citizen.org',
      }
    end

    context "created with valid attributes" do
      subject      { User.create!(@valid_attributes) }
      it           { should be_instance_of User }
      it           { should be_valid }
      its(:errors) { should be_empty }
      its(:uid)    { should match /[0-9a-f\-]{36}/ }
    end

    context "created without an email address" do
      subject      { User.create(@valid_attributes.reject{|k,v| k == :email }) }
      it           { should_not be_valid }
      its(:errors) { should_not include("I'm sorry, your account hasn't been approved yet.") }
      its(:errors) { should_not be_empty }
    end

    context "created with an invalid email address" do
      subject      { User.create(@valid_attributes.merge(email: 'not_valid')) }
      it           { should_not be_valid }
      its(:errors) { should_not include("I'm sorry, your account hasn't been approved yet.") }
      its(:errors) { should_not be_empty }
    end
  end

  describe "#find_or_create_from_omniauth" do
    let(:email) { 'testy@example.gov' }
    let(:uid) { '12345' }

    context "with google auth hash" do
      let(:provider) { 'google_oauth2' }
      let(:auth_hash) do
        OmniAuth::AuthHash.new({
          provider: provider,
          uid: uid,
          info: {
            email: email
          }
        })
      end

      context "when user exists with authentication matching provider and UID" do
        before :each do
          #TODO: factories!
          User.create! do |user|
            user.email = 'somebody_else@example.gov'
            user.authentications.build(provider: provider, uid: uid)
          end

          @user = User.find_or_create_from_omniauth(auth_hash)
        end

        it "finds user with matching google uid" do
          expect(@user).to be
        end
      end

      context "when user exists with matching email" do
        before :each do
          User.create!(email: email)

          @user = User.find_or_create_from_omniauth(auth_hash)
        end

        it "finds user with matching email" do
          expect(@user).to be
        end

        it "creates an authentication record for the user" do
          expect(@user.authentications.where(provider: provider, uid: uid)).to be
        end
      end

      context "when no user exists" do
        before :each do
          @user = User.find_or_create_from_omniauth(auth_hash)
        end

        it "creates user" do
          expect(@user).to be
        end

        it "creates an authentication record for the user" do
          expect(@user.authentications.where(provider: provider, uid: uid)).to be
        end
      end
    end
  end

  describe "#set_authentication_token" do
    let(:email) { 'testy@example.gov' }
    let(:time) { Date.new(1999, 12, 31) }

    before :each do
      Timecop.freeze time
      allow(Devise.token_generator).to receive(:generate) { ['raw', 'enc'] }
      @user = User.create!(email: email)
    end

    after :each do
      Timecop.return
    end

    it "sets an authentication_token" do
      @user.set_authentication_token
      @user.reload
      expect(@user.authentication_token).to eq('enc')
    end

    it "records the time that the token was set" do
      @user.set_authentication_token
      @user.reload
      expect(@user.authentication_sent_at).to eq(time)
    end

    it "returns the raw token" do
      expect(@user.set_authentication_token).to eq('raw')
    end

    it "sends email to the user with the raw token" do
      expect(@user).to receive(:send_devise_notification).with(:authentication_instructions, 'raw', anything)
      @user.set_authentication_token
    end
  end

  describe "#verify_authentication_token" do
    let(:email) { 'testy@example.gov' }
    let(:raw_token) { 'token' }
    let(:token) { Devise.token_generator.digest(self, :authentication_token, raw_token) }

    before :each do
      @user = User.create!(email: email, authentication_token: token)
    end

    it "returns true for a valid token" do
      expect(@user.verify_authentication_token(raw_token)).to be true
    end

    it "returns false for a blank token" do
      expect(@user.verify_authentication_token('')).to be false
    end

    it "returns false for an invalid token" do
      expect(@user.verify_authentication_token('foobar')).to be false
    end
  end
end
