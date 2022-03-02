defmodule Cldr.Unit.Additional do
  @moduledoc """
  Additional domain-specific units can be defined
  to suit application requirements. In the context
  of `ex_cldr` there are two parts of configuring
  additional units.

  1. Configure the unit, base unit and conversion in
  `config.exs`. This is a requirement since units are
  compiled into code.

  2. Configure the localizations for the additional
  unit in a CLDR backend module.

  Once configured, additional units act and behave
  like any of the predefined units of measure defined
  by CLDR.

  ## Configuring a unit in config.exs

  Under the application `:ex_cldr_units` define
  a key `:additional_units` with the required
  unit definitions.  For example:
  ```elixir
  config :ex_cldr_units, :additional_units,
    vehicle: [base_unit: :unit, factor: 1, offset: 0, sort_before: :all],
    person: [base_unit: :unit, factor: 1, offset: 0, sort_before: :all]
  ```
  This example defines two additional units: `:vehicle` and
  `:person`.  The keys `:base_unit`, and `:factor` are required.
  The key `:offset` is optional and defaults to `0`. The
  key `:sort_before` is optional and defaults to `:none`.

  ### Configuration keys

  * `:base_unit` is the common denominator that is used
    to support conversion between like units. It can be
    any atom value. For example `:liter` is the base unit
    for volume units, `:meter` is the base unit for length
    units.

  * `:factor` is used to convert a unit to its base unit in
    order to support conversion. When converting a unit to
    another compatible unit, the unit is first multiplied by
    this units factor then divided by the target units factor.

  * `:offset` is added to a unit after applying its base factor
    in order to convert to another unit.

  * `:sort_before` determines where in this *base unit* sorts
    relative to other base units.  Typically this is set to
    `:all` in which case this base unit sorts before all other
    base units or`:none` in which case this base unit sorted
    after all other base units. The default is `:none`. If in
    doubt, leave this key to its default.

  * `:systems` is list of measurement systems to which this
    unit belongs. The known measurement systems are `:metric`,
    `:uksystem` and `:ussystem`. The default is
    `[:metric, :ussystem, :uksystem]`.

  ## Defining localizations

  Localizations are defined in a backend module through adding
  `use Cldr.Unit.Additional` to the top of the backend module
  and invoking `Cldr.Unit.Additional.unit_localization/4` for
  each localization.

  See `Cldr.Unit.Additional.unit_localization/4` for further
  information.

  Note that one invocation of the macro is required for
  each combination of locale, style and unit. An exception
  will be raised at runtime is a localization is expected
  but is not found.

  """
  @root_locale_name Cldr.Config.root_locale_name()

  defmacro __using__(_opts) do
    module = __CALLER__.module

    quote do
      @before_compile Cldr.Unit.Additional
      @after_compile Cldr.Unit.Additional

      import Cldr.Unit.Additional
      Module.register_attribute(unquote(module), :custom_localizations, accumulate: true)
    end
  end

  @doc false
  defmacro __before_compile__(_ast) do
    caller = __CALLER__.module
    target_module = Module.concat(caller, Unit.Additional)

    caller
    |> Module.get_attribute(:custom_localizations)
    |> Cldr.Unit.Additional.group_localizations()
    |> Cldr.Unit.Additional.define_localization_module(target_module)
  end

  @doc """
  Although defining a unit in `config.exs` is enough to create,
  operate on and serialize an additional unit, it cannot be
  localised without defining localizations in an `ex_cldr`
  backend module.  For example:
  ```elixir
  defmodule MyApp.Cldr do
    use Cldr.Unit.Additional

    use Cldr,
      locales: ["en", "fr", "de", "bs", "af", "af-NA", "se-SE"],
      default_locale: "en",
      providers: [Cldr.Number, Cldr.Unit, Cldr.List]

    unit_localization(:person, "en", :long,
      one: "{0} person",
      other: "{0} people",
      display_name: "people"
    )

    unit_localization(:person, "en", :short,
      one: "{0} per",
      other: "{0} pers",
      display_name: "people"
    )

    unit_localization(:person, "en", :narrow,
      one: "{0} p",
      other: "{0} p",
      display_name: "p"
    )
  end
  ```

  Note the additions to a typical `ex_cldr`
  backend module:

  * `use Cldr.Unit.Additional` is required to
    define additional units

  * use of the `unit_localization/4` macro in
    order to define a localization.

  One invocation of `unit_localization` should
  made for each combination of unit, locale and
  style.

  ### Parameters to unit_localization/4

  * `unit` is the name of the additional
  unit as an `atom`.

  * `locale` is the locale name for this
    localization. It should be one of the locale
    configured in this backend although this
    cannot currently be confirmed at compile time.

  * `style` is one of `:long`, `:short`, or
    `:narrow`.

  * `localizations` is a keyword like of localization
    strings. Two keys - `:display_name` and `:other`
    are mandatory. They represent the localizations for
    a non-count display name and `:other` is the
    localization for a unit when no other pluralization
    is defined.

  ### Localisations

  Localization keyword list defines localizations that
  match the plural rules for a given locale. Plural rules
  for a given number in a given locale resolve to one of
  six keys:

  * `:zero`
  * `:one` (singular)
  * `:two` (dual)
  * `:few` (paucal)
  * `:many` (also used for fractions if they have a separate class)
  * `:other` (required—general plural form—also used if the language only has a single form)

  Only the `:other` key is required. For english,
  providing keys for `:one` and `:other` is enough. Other
  languages have different grammatical requirements.

  The key `:display_name` is used by the function
  `Cldr.Unit.display_name/1` which is primarily used
  to support UI applications.

  """
  defmacro unit_localization(unit, locale, style, localizations) do
    module = __CALLER__.module
    {localizations, _} = Code.eval_quoted(localizations)
    localization = Cldr.Unit.Additional.validate_localization!(unit, locale, style, localizations)

    quote do
      Module.put_attribute(
        unquote(module),
        :custom_localizations,
        unquote(Macro.escape(localization))
      )
    end
  end

  # This is the empty module created if the backend does not
  # include `use Cldr.Unit.Additional`

  @doc false
  def define_localization_module(%{} = localizations, module) when localizations == %{} do
    IO.warn(
      "The CLDR backend #{inspect(module)} calls `use Cldr.Unit.Additional` " <>
        "but does not have any localizations defined",
      []
    )

    quote bind_quoted: [module: module] do
      defmodule module do
        def units_for(locale, style) do
          %{}
        end

        def known_locale_names do
          unquote([])
        end

        def additional_units do
          unquote([])
        end
      end
    end
  end

  def define_localization_module(localizations, module) do
    additional_units =
      localizations
      |> Map.values()
      |> hd()
      |> Map.values()
      |> hd()
      |> Map.keys()

    quote bind_quoted: [
            module: module,
            localizations: Macro.escape(localizations),
            additional_units: additional_units
          ] do
      defmodule module do
        for {locale, styles} <- localizations do
          for {style, formats} <- styles do
            def units_for(unquote(locale), unquote(style)) do
              unquote(Macro.escape(formats))
            end
          end
        end

        def units_for(locale, style) do
          %{}
        end

        def known_locale_names do
          unquote(Map.keys(localizations))
        end

        def additional_units do
          unquote(additional_units)
        end
      end
    end
  end

  @doc false
  def __after_compile__(env, _bytecode) do
    additional_module = Module.concat(env.module, Unit.Additional)
    additional_units = additional_module.additional_units()
    additional_locales = MapSet.new(additional_module.known_locale_names())
    backend_locales = MapSet.new(env.module.known_locale_names() -- [@root_locale_name])
    styles = Cldr.Unit.known_styles()

    case MapSet.to_list(MapSet.difference(backend_locales, additional_locales)) do
      [] ->
        :ok

      other ->
        IO.warn(
          "The locales #{inspect(other)} configured in " <>
            "the CLDR backend #{inspect(env.module)} " <>
            "do not have localizations defined for additional units #{inspect(additional_units)}.",
          []
        )
    end

    for locale <- MapSet.intersection(backend_locales, additional_locales),
        style <- styles do
      with found_units when is_map(found_units) <- additional_module.units_for(locale, style),
           [] <- additional_units -- Map.keys(found_units) do
        :ok
      else
        :error ->
          IO.warn(
            "#{inspect(env.module)} does not define localizations " <>
              "for locale #{inspect(locale)} with style #{inspect(style)}",
            []
          )

        not_defined when is_list(not_defined) ->
          IO.warn(
            "#{inspect(env.module)} does not define localizations " <>
              "for locale #{inspect(locale)} with style #{inspect(style)} " <>
              "for units #{inspect(not_defined)}",
            []
          )
      end
    end
  end

  @doc false
  def group_localizations(localizations) when is_list(localizations) do
    localizations
    |> Enum.group_by(
      fn localization -> localization.locale end,
      fn localization -> Map.take(localization, [:style, :unit, :localizations]) end
    )
    |> Enum.map(fn {locale, rest} ->
      value =
        Enum.group_by(
          rest,
          fn localization -> localization.style end,
          fn localization -> {localization.unit, parse(localization.localizations)} end
        )
        |> Enum.map(fn {style, list} -> {style, Map.new(list)} end)

      {locale, Map.new(value)}
    end)
    |> Map.new()
  end

  defp parse(localizations) do
    Enum.map(localizations, fn
      {:display_name, name} ->
        {:display_name, name}

      {:gender, gender} ->
        {:gender, gender}

      {grammatical_case, counts} ->
        counts =
          Enum.map(counts, fn {count, template} ->
            {count, Cldr.Substitution.parse(template)}
          end)

        {grammatical_case, Map.new(counts)}
    end)
    |> Map.new()
  end

  @doc false
  def validate_localization!(unit, locale, style, localizations) do
    unless is_atom(unit) do
      raise ArgumentError, "Unit name must be an atom. Found #{inspect(unit)}"
    end

    unless style in [:short, :long, :narrow] do
      raise ArgumentError, "Style must be one of :short, :long or :narrow. Found #{inspect(style)}"
    end

    unless is_binary(locale) or is_atom(locale) do
      raise ArgumentError, "Locale name must be a string or an atom. Found #{inspect(locale)}"
    end

    unless Keyword.keyword?(localizations) do
      raise ArgumentError, "Localizations must be a keyword list. Found #{inspect(localizations)}"
    end

    unless Keyword.has_key?(localizations, :nominative) do
      raise ArgumentError, "Localizations must have an :nominative key"
    end

    unless Map.has_key?(localizations[:nominative], :other) do
      raise ArgumentError, "The nominative case must have an :other key"
    end

    unless Keyword.has_key?(localizations, :display_name) do
      raise ArgumentError, "Localizations must have a :display_name key"
    end

    %{unit: unit, locale: atomize(locale), style: style, localizations: localizations}
  end

  defp atomize(locale) when is_atom(locale), do: locale
  defp atomize(locale) when is_binary(locale), do: String.to_atom(locale)

  @doc false
  @default_systems [:metric, :uksystem, :ussystem]
  @default_sort_before :none
  @default_offset 0

  def conversions do
    :ex_cldr_units
    |> Application.get_env(:additional_units, [])
    |> conversions()
  end

  defp conversions(config) when is_list(config) do
    config
    |> Enum.map(fn {unit, config} ->
      if Keyword.keyword?(config) do
        new_config =
          config
          |> Keyword.put_new(:offset, @default_offset)
          |> Keyword.put_new(:sort_before, @default_sort_before)
          |> Keyword.put_new(:systems, @default_systems)
          |> validate_unit!

        {unit, new_config}
      else
        raise ArgumentError,
              "Additional unit configuration for #{inspect(unit)} must be a keyword list. Found #{
                inspect(config)
              }"
      end
    end)
  end

  defp conversions(config) do
    raise ArgumentError,
          "Additional unit configuration must be a keyword list. Found #{inspect(config)}"
  end

  defp validate_unit!(unit) do
    unless Keyword.keyword?(unit) do
      raise ArgumentError,
            "Additional unit configuration must be a keyword list. Found #{inspect(unit)}"
    end

    unless Keyword.has_key?(unit, :factor) do
      raise ArgumentError, "Additional unit configuration must have a :factor configured"
    end

    unless (list = Keyword.fetch!(unit, :systems)) |> is_list() do
      raise ArgumentError, "Additional unit systems must be a list. Found #{inspect(list)}"
    end

    unless Enum.all?(Keyword.fetch!(unit, :systems), &(&1 in @default_systems)) do
      raise ArgumentError,
            "Additional unit valid measurement systems are " <>
              "#{inspect(@default_systems)}. Found #{inspect(Keyword.fetch!(unit, :systems))}"
    end

    unless (base = Keyword.fetch!(unit, :base_unit)) |> is_atom() do
      raise ArgumentError, "Additional unit :base_unit must be an atom. Found #{inspect(base)}"
    end

    case Keyword.fetch!(unit, :factor) do
      x when is_number(x) ->
        :ok

      %{numerator: numerator, denominator: denominator}
      when is_number(numerator) and is_number(denominator) ->
        :ok

      other ->
        raise ArgumentError,
              "Additional unit factor must be a number or a rational " <>
                "of the form %{numerator: number, denominator: number}. Found #{inspect(other)}"
    end

    unit
  end

  @doc false
  def additional_units do
    Keyword.keys(conversions())
  end

  @doc false
  def systems_for_units do
    conversions()
    |> Enum.map(fn {k, v} -> {k, v[:systems]} end)
  end

  @doc false
  def merge_base_units(core_base_units) do
    additional_base_units =
      orderable_base_units()
      |> Enum.reject(fn {k, _v} -> Keyword.has_key?(core_base_units, k) end)

    merge_base_units(core_base_units, additional_base_units)
  end

  def merge_base_units(core_base_units, additional_base_units, acc \\ [])

  # Insert units at the head
  def merge_base_units(core_base_units, [{k, :all} | rest], acc) do
    merge_base_units(core_base_units, rest, [{k, k} | acc])
  end

  # Insert units at the tail. Since the additional units are sorted
  # we can guarantee that when we hit one with :none we can just take
  # everything left
  def merge_base_units(core_base_units, [{_k, :none} | _rest] = additional, acc) do
    tail_base_units = Enum.map(additional, fn {k, _v} -> {k, k} end)
    acc ++ core_base_units ++ tail_base_units
  end

  def merge_base_units(core_base_units, [], acc) do
    acc ++ core_base_units
  end

  def merge_base_units([], additional, acc) do
    tail_base_units = Enum.map(additional, fn {k, _v} -> {k, k} end)
    acc ++ tail_base_units
  end

  def merge_base_units([{k1, _v1} = head | other] = core_base_units, additional, acc) do
    case Keyword.pop(additional, k1) do
      {nil, _rest} -> merge_base_units(other, additional, acc ++ [head])
      {{v2, _}, rest} -> merge_base_units(core_base_units, rest, acc ++ [{v2, v2}])
    end
  end

  @doc false
  def base_units do
    conversions()
    |> Enum.map(fn {_k, v} -> {v[:base_unit], v[:base_unit]} end)
    |> Enum.uniq()
    |> Keyword.new()
  end

  @doc false
  def orderable_base_units do
    conversions()
    |> Enum.sort(fn {_k1, v1}, {_k2, v2} ->
      cond do
        Keyword.get(v1, :sort_before) == :all ->
          true

        Keyword.get(v1, :sort_before) == :none ->
          false
          Keyword.get(v1, :sort_before) < Keyword.get(v2, :sort_before)
      end
    end)
    |> Keyword.values()
    |> Enum.map(&{&1[:base_unit], &1[:sort_before]})
    |> Enum.uniq()
    |> Keyword.new()
  end
end
