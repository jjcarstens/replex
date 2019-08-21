# Usage:\nsendiq [-i File Input][-s Samplerate][-l] [-f Frequency] [-h Harmonic number] \n\
# -i            path to File Input \n\
# -s            SampleRate 10000-250000 \n\
# -f float      central frequency Hz(50 kHz to 1500 MHz),\n\
## -l            loop mode for file input\n\
# -h            Use harmonic number n\n\
# -t            IQ type (i16 default) {i16,u8,float,double}\n\
# -?            help (this help).\n\
# \n",\

defmodule Replex do
  @default_opts [
    sample_rate: 200_000,
    iq_type: :i16
  ]

  def replay(file, frequency, opts) do
    IO.inspect({file, frequency, opts})
  end

  defmacro defreplay(name, file, frequency, opts) do
    # name = Path.basename(file)
    #       |> String.split(".iq")
    #       |> hd
    # pos = :elixir_locals.cache_env(__CALLER__)
    quote location: :keep do
      # :elixir_def.store_definition(:def, true, unquote(name), [unquote(file), unquote(frequency), unquote(opts)], unquote(pos))
      def unquote(name) do
        Replex.replay(unquote(file), unquote(frequency), unquote(opts))
      end
    end
  end
end
