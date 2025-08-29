module ApplicationHelper
  def inr(number)
    parts = number.to_s.split(".")
    integer_part = parts[0]
    decimal_part = parts[1]

    formatted_integer_part = integer_part.gsub(/(\d+?)(?=(\d\d)+(\d)(?!\d))/, '\\1,')

    if decimal_part
      "#{formatted_integer_part}.#{decimal_part}"
    else
      "#{formatted_integer_part}"
    end
  end

  def precision_inr(number, precision: 2)
    precise = number_with_precision(number, precision:)
    inr(precise)
  end
end
