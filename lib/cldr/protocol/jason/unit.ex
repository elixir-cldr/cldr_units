if Cldr.Config.ensure_compiled?(Jason) &&
    !Cldr.Unit.exclude_protocol_implementation(Json.Encoder) do
  defimpl Jason.Encoder, for: Cldr.Unit do
    def encode(struct, opts) do
      struct
      |> Map.take([:unit, :value])
      |> Jason.Encode.map(opts)
    end
  end
end
