class Api::V1::Shopkeeper::DevicesController < Api::V1::Shopkeeper::BaseController
  before_action :set_device, only: %i[destroy]

  # POST /api/v1/shopkeeper/devices
  #
  # Idempotent registration. Same (platform, token) tuple on a re-POST
  # updates last_active_at instead of creating a duplicate. Re-binding a
  # token to a different shopkeeper (e.g. user signed out + new user
  # signed in on same device) reassigns the device row.
  def create
    authorize ApplicationPushDevice

    device = ApplicationPushDevice.find_or_initialize_by(
      platform: device_params[:platform],
      token: device_params[:token]
    )
    device.owner = current_shopkeeper
    device.bundle_id = device_params[:bundle_id]
    device.last_active_at = Time.current

    if device.save
      render json: ApplicationPushDeviceSerializer.new(device).serializable_hash, status: device.previously_new_record? ? :created : :ok
    else
      render_validation_error(device)
    end
  end

  # DELETE /api/v1/shopkeeper/devices/:id
  def destroy
    authorize @device

    @device.destroy
    head :no_content
  end

  private

  def set_device
    @device = current_shopkeeper.application_push_devices.find(params[:id])
  end

  def device_params
    params.require(:device).permit(:token, :platform, :bundle_id)
  end
end
