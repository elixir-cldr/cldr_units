if Cldr.Config.ensure_compiled?(Phoenix.HTML.Safe) &&
    !Cldr.Unit.exclude_protocol_implementation(Phoenix.HTML.Safe) do
  defimpl Phoenix.HTML.Safe, for: Cldr.Unit do
    def to_iodata(unit) do
      Phoenix.HTML.Safe.to_iodata(Cldr.Unit.to_string!(unit))
    end
  end
end