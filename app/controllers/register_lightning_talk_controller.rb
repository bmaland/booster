class RegisterLightningTalkController < ApplicationController

  def start
    if current_user
      redirect_to '/register_lightning_talk/talk'
    end
    @user = User.new
    @user.registration = Registration.new
  end

  def create_user
    @user = User.new(params[:user])
    @user.registration = Registration.new
    @user.registration.ticket_type_old = 'lightning'
    @user.registration.manual_payment = true
    @user.accepted_privacy_guidelines = true
    @user.email.strip! if @user.email.present?
    @user.registration_ip = request.remote_ip
    @user.roles = params[:roles].join(',') unless params[:roles] == nil

    if @user.save
      UserSession.create(:login => @user.email, :password => @user.password)
      @user.registration.save!
      redirect_to '/register_lightning_talk/talk'
    else
      render action: :start
    end
  end

  def talk
    @talk = LightningTalk.new
    @talk_types = TalkType.talks
  end

  def create_talk
    talk_type = TalkType.find_by_id(@talk.talk_type_id)
    @talk = talk_type == "LightningTalk" ? LightningTalk.new(params[:talk]) : ShortTalk.new(params[:talk])
    @talk.talk_type = talk_type
    @talk.year = AppConfig.year
    @talk.users << current_user
    if @talk.save
      current_user.update_ticket_type!

      BoosterMailer.talk_confirmation(current_user, @talk, talk_url(@talk)).deliver
      SlackNotifier.notify_talk(@talk)

      if current_user.has_all_statistics? && current_user.bio && current_user.bio.good_enough?
        redirect_to '/register_lightning_talk/finish'
      else
        redirect_to '/register_lightning_talk/details'
      end
    else
      render action: :talk
    end
  end

  def details
    @user = current_user
    @user.create_bio
  end

  def create_details
    @user = current_user
    @user.update_attributes(params[:user])

    if @user.save
      redirect_to '/register_lightning_talk/finish'
    else
      render action: :details
    end
  end

end