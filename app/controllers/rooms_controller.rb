class RoomsController < ApplicationController

  before_filter :require_admin

  respond_to :html

  # GET /rooms
  def index
    @rooms = Room.all
  end

  # GET /rooms/1
  def show
    @room = Room.find(params[:id])
  end

  # GET /rooms/new
  def new
    @room = Room.new
  end

  # GET /rooms/1/edit
  def edit
    @room = Room.find(params[:id])
  end

  # POST /rooms
  def create
    @room = Room.new(params[:room])

    if @room.save
      redirect_to :rooms, notice: 'Room was successfully created.'
    else
      render action: :new
    end
  end

  # PUT /rooms/1
  def update
    @room = Room.find(params[:id])

    if @room.update_attributes(params[:room])
      redirect_to @room, notice: 'Room was successfully updated.'
    else
      render action: :edit
    end
  end

  # DELETE /rooms/1
  def destroy
    @room = Room.find(params[:id])
    @room.destroy

    redirect_to rooms_url
  end
end
