module NameIterator
  private

  def iterate_name
    new_name = @name.clone

    match = new_name.match(/\((\d+)\)\z/)
    if match
      number = match[1].to_i
      new_name.sub(/\(#{number}\)\z/, "(#{number + 1})")
    else
      new_name + "(2)"
    end
  end
end
