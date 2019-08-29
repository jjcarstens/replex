# replex

Use Elixir to replay radio signals on a Raspberry Pi

## About

This was inspired by the project [`rpitx`](https://github.com/F5OEO/rpitx) which allows
you to transmit signals from 5 KHz - 1500 MHz from a single GPIO pin. There is a lot
of really cool stuff in `rpitx`, but this only focuses on the [`sendiq`](https://github.com/F5OEO/rpitx/blob/master/src/sendiq.cpp)
binary for transmitting an I/Q recording file.

If you're new to radio, SDR, and replaying radio signals, I have a full write-up
about the motiviation for this library and how to go through the full process at
[Nerves @ 434 MHz](https://embedded-elixir.com/post/2019-08-29-nerves-at-434-mhz/)

## How to Use

Install the dep:

```elixir
def deps do
  {
    #...other deps
    {:replex, "~> 0.1"}
  }
end
```

Then you need to make sure you have your recording files as part of your project.
The easiest way to do this is to put into the `priv/` under your project root.

From there, you can use it like so:

```elixir
defmodule Radio do
  def fan_light() do
    file = Path.join(:code.priv_dir(:radio), "fan_light.iq")
    Replex.replay(file, 433907740, sample_rate: 250_000)
  end
end
```

```sh
iex()> Radio.fan_light
:ok
```

## Caveats

Because of the nature of replaying radio signals, there is no guarantee on
the success or failure of your radio signal _actually_ being received. Devices
won't send back an `ack` or any response to the action. So this will always
return `:ok` as long as the binary ran and signal was attempted but you won't
_really know_ that it worked.

A recommendation would be to just obnoxiously blast the signal asyncronously
and play the numbers game. _Surely_ the device will receive it 1 out of 5 times:

```elixir
Task.async(fn ->
  Room.lights_on
  Room.lights_on
  Room.lights_on
  Room.lights_on
end)
```

That said, if the signal is _binary_ (meaning it is the same signal to toggle
on and off), then this process won't really work. Unless you're hoping to bring
back disco and flashing lights 🕺
 
## Goals

* Support compiling `sendiq` (I mainly compile and include in release)
* Support more raspberry pi than `rpi3`