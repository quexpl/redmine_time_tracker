module Chronos
  class TimeTrackersController < ApiBaseController
    accept_api_auth :index, :show, :start, :update, :stop

    before_action :get_time_tracker, only: [:show, :update, :stop, :destroy]
    before_action :authorize_global, only: [:index, :show, :start, :stop, :update, :destroy]
    before_action :find_optional_project, :authorize_book, only: [:stop]
    before_action :authorize_foreign, only: [:show, :update, :stop, :destroy]
    before_action :authorize_update_time, only: [:update]

    def index
      time_trackers = allowed_to?('index_foreign') ? Chronos::TimeTracker.all : User.current.chronos_time_tracker
      respond_with_success time_trackers
    end

    def show
      respond_with_success @time_tracker
    end

    def start
      time_tracker = Chronos::TimeTracker.start start_time_tracker_params
      if time_tracker.persisted?
        respond_with_success time_tracker
      else
        respond_with_error :bad_request, time_tracker.errors.full_messages
      end
    end

    def update
      if @time_tracker.update update_time_tracker_params
        respond_with_success
      else
        respond_with_error :bad_request, @time_tracker.errors.full_messages
      end
    end

    def stop
      time_log = @time_tracker.stop
      time_booking = time_log && time_log.time_booking
      if !time_log || time_log.persisted?
        respond_with_success time_log: time_log, time_booking: time_booking
      else
        respond_with_error :bad_request, time_log.errors.full_messages
      end
    end

    def destroy
      @time_tracker.destroy
      respond_with_success
    end

    private
    def start_time_tracker_params
      time_tracker_params = params.require(:time_tracker).permit(:issue_id, :comments)
      time_tracker_params.delete :comments if time_tracker_params[:issue_id].present?
      time_tracker_params
    end

    def update_time_tracker_params
      params.require(:time_tracker).permit(:start, :comments, :round, :project_id, :issue_id, :activity_id)
    end

    def get_time_tracker
      @time_tracker = params[:id] == 'current' ? current_time_tracker : time_tracker_from_id
      respond_with_error :not_found, t('chronos.api.time_trackers.errors.not_found') unless @time_tracker.present?
      @request_resource = @time_tracker
    end

    def current_time_tracker
      User.current.chronos_time_tracker
    end

    def time_tracker_from_id
      Chronos::TimeTracker.find_by id: params[:id]
    end

    def authorize_book
      if @project.present? && !allowed_to?('book', 'chronos/time_logs')
        respond_with_error :forbidden, t('chronos.api.time_trackers.errors.booking_forbidden')
      end
    end
  end
end