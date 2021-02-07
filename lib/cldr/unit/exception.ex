defmodule Cldr.Unit.IncompatibleUnitsError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnknownUnitCategoryError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnknownUnitPreferenceError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnitNotConvertibleError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnknownBaseUnitError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnknownUsageError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnitNotTranslatableError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.InvalidSystemKeyError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Unit.UnknownMeasurementSystemError do
  @moduledoc false
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
