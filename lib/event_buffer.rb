class EventBuffer
  def initialize(size)
    @buffer = []
    @size = size
  end

  def <<(event)
    @buffer << event

    @buffer.shift if @buffer.size > @size
  end

  def each
    @buffer.each do |event|
      yield event
    end
  end

  def last
    @buffer.last
  end
end
