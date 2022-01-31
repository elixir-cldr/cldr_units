if Cldr.Config.ensure_compiled?(Ratio) &&
    !Cldr.Unit.exclude_protocol_implementation(Ratio) do
  defimpl Jason.Encoder, for: Ratio do
    def encode(struct, opts) do
      struct
      |> Map.take([:numerator, :denominator])
      |> Jason.Encode.map(opts)
    end
  end
end