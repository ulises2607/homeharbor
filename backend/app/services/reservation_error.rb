class ReservationError < StandardError
  attr_reader :code, :status

  def initialize(code, message, status: :conflict)
    @code, @status = code, status
    super(message)
  end
end
