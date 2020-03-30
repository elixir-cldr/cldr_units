defmodule Cldr.Unit.IncompatibleUnitsError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnknownUnitCategoryError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnknownUnitPreferenceError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnitNotConvertibleError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnknownBaseUnitError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
