require "securerandom"

class RegisterWorkshopController < ApplicationController

  before_filter :setup_talk_types, only: [:talk, :create_talk]

  def start
    if current_user
      redirect_to register_workshop_talk_url
    end
    @user = User.new
    @user.registration = Registration.new
  end

  def create_user
    @user = User.new(params[:user])
    @user.create_registration
    @user.registration.ticket_type_old = 'speaker'
    @user.registration.manual_payment = true
    @user.accepted_privacy_guidelines = true
    @user.email.strip! if @user.email.present?
    @user.registration_ip = request.remote_ip
    @user.roles = params[:roles].join(',') if params[:roles]

    if @user.save
      UserSession.create(login: @user.email, password: @user.password)
      @user.registration.save!
      redirect_to register_workshop_talk_url
    else
      render action: :start
    end
  end

  def talk
    @workshop = Workshop.new
  end

  def create_talk
    @workshop = Workshop.new(params[:talk])
    @workshop.appropriate_for_roles = params[:appropriate_for_roles].join(',') if params[:appropriate_for_roles]
    @workshop.users << current_user

    if @workshop.save
      current_user.update_ticket_type!

      if has_entered_additional_speaker_email
        add_additional_speaker
      end

      BoosterMailer.talk_confirmation(current_user, @workshop, talk_url(@workshop)).deliver
      SlackNotifier.notify_talk(@workshop)

      if current_user.has_all_statistics?
        redirect_to register_workshop_finish_url
      else
        redirect_to register_workshop_details_url
      end
    else
      render action: :talk
    end
  end

  def add_additional_speaker
    additional_speaker_email = params[:additional_speaker_email]

    if additional_speaker_already_has_registered_user(additional_speaker_email)
      send_email_to_organizers_to_go_fix_it(additional_speaker_email)
    else
      create_user_for_additional_speaker(additional_speaker_email, @workshop)
    end
  end

  def send_email_to_organizers_to_go_fix_it(additional_speaker_email)
    BoosterMailer.organizer_notification("User #{additional_speaker_email} should be a speaker at #{@workshop.title}. Go fix!").deliver
  end

  def create_user_for_additional_speaker(additional_speaker_email, talk)
    additional_speaker = User.create_unfinished(additional_speaker_email, 'speaker')
    additional_speaker.save(:validate => false)
    talk.users << additional_speaker
    talk.save!

    BoosterMailer.additional_speaker(current_user, additional_speaker, @workshop).deliver
  end

  def additional_speaker_already_has_registered_user(additional_speaker_email)
    User.find_by_email(additional_speaker_email)
  end

  def has_entered_additional_speaker_email
    params[:additional_speaker_email].present?
  end

  def details
    @user = current_user
    @user.create_bio
  end

  def create_details

    @user = current_user
    @user.update_attributes(params[:user])

    if @user.save
      redirect_to register_workshop_finish_url
    else
      render :action => :details
    end
  end

  private
  def setup_talk_types
    @talk_types = current_user.try(:is_admin?) ? TalkType.all : TalkType.workshops
  end

end