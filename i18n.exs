defmodule Plural do
  def get_plural_form( locale, count ) do
    module = Module.concat( __MODULE__, String.upcase( locale ) )
    case :code.is_loaded( module ) do
      false -> raise "The locale #{locale} is not supported"
      { :file, _ } -> module.get_plural_form(count)
    end
  end
end

defmodule Plural.EN do
  def get_plural_form( count ) when count == 1, do: :one
  def get_plural_form( _count )               , do: :other
end

defmodule Plural.FR do
  def get_plural_form( count ) when is_integer( count ) and count in [ 0, 1 ], do: :one
  def get_plural_form( count ) when is_float( count ) and count < 2          , do: :one
  def get_plural_form( _count )                                              , do: :other
end

defmodule Plural.RU do
  def get_plural_form( count ) when is_integer( count ) and rem( count, 10 ) == 1 and rem( count, 100 ) != 11, do: :one
  def get_plural_form( count ) when is_integer( count ) and ( rem( count, 10 ) in 2..4 ) and not( rem( count, 100 ) in 12..14 ), do: :few
  def get_plural_form( count ) when is_integer( count ) and ( ( rem( count, 10 ) in [ 0, 5, 6, 7, 8, 9 ] ) or ( rem( count, 100 ) in 11..14 ) ), do: :many
  def get_plural_form( _count ), do: :other
end

defmodule Translator do

  defmacro __using__( _options ) do
    quote do
      Module.register_attribute __MODULE__, :locales, accumulate: true,
                                                         persist: false
      import unquote( __MODULE__ ), only: [ locale: 2 ]
      @before_compile unquote( __MODULE__ )
    end
  end

  defmacro __before_compile__( env ) do
    compile( Module.get_attribute( env.module, :locales ) )
  end

  defmacro locale( name, mappings ) do
    quote bind_quoted: [ name: name, mappings: mappings ] do
      @locales { name, mappings }
    end
  end

  def compile( translations ) do
    translations_ast = for { locale, mappings } <- translations do
      deftranslations( locale, "", mappings )
    end
    quote do
      def t( locale, path, bindings \\ [] )
      unquote( translations_ast )
      def t( locale, path, count ) when is_number( count ) do
        t( locale, "#{path}.#{Plural.get_plural_form( locale, count )}" )
      end
      def t( _locale, _path, _bindings ), do: { :error, :no_translation }
    end
  end

  defp deftranslations( locale, current_path, mappings ) do
    for { key, val } <- mappings do
      path = append_path( current_path, key )
      if Keyword.keyword?( val ) do
        deftranslations( locale, path, val )
      else
        quote do
          def t( unquote( locale ), unquote( path ), bindings ) do
            unquote( interpolate( val ) )
          end
        end
      end
    end
  end

  defp interpolate( string ) do
    ~r/(?<head>)%{[^}]+}(?<tail>)/
      |> Regex.split( string, on: [ :head, :tail ])
      |> Enum.reduce "", fn( << "%{" <> rest >>, acc ) ->
          key = String.to_atom( String.rstrip( rest, ?} ) )
          quote do
            unquote( acc ) <> to_string( Dict.fetch!( bindings, unquote( key ) ) )
          end
        segment, acc -> quote do: ( unquote( acc ) <> unquote( segment ) )
      end
  end

  defp append_path( "", next ), do: to_string( next )
  defp append_path( current, next ), do: "#{current}.#{next}"

end

defmodule I18n do

  use Translator

  # http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html
  # For pluralization rules we're going to use the
  # conventional keys: one / two / few / many / other

  locale "en",
    flash: [
      hello: "Hello %{first} %{last}!",
      bye:   "Bye, %{name}!"
    ],
    users: [
      title: "Users",
    ],
    title: [
      user: [
        one: "user",
        other: "users",
      ],
    ]

  locale "fr",
    flash: [
      hello: "Salut %{first} %{last}",
      bye:   "Au revoir, %{name}!"
    ],
    users: [
      title: "Utilisateurs",
    ],
    title: [
      user: [
        one:   "utilisateur",
        other: "utilisateurs",
      ],
    ]
  locale "ru",
    flash: [
      hello: "Привет %{first} %{last}!",
      bye:   "Всего хорошего, %{name}!",
    ],
    users: [
      title: "Пользователи",
    ],
    title: [
      user: [
        one:   "пользователь",
        few:   "пользователя",
        many:  "пользователей",
        other: "пользователей"
      ],
    ]

end

# ExUnit.start()
# 
# defmodule Plural.ENTest do
#   use ExUnit.Case
#   import Plural.EN, only: [ get_plural_form: 1 ]
# 
#   test ":one" do
#     assert get_plural_form( 1 ) == :one
#   end
# 
#   test ":other" do
#     [ 0, 2, 0.5, 1.2, 3, 4, 5.5, 100, 111, 112 ]
#       |> Enum.each( fn( count )->
#         assert get_plural_form( count ) == :other
#       end)
#   end
# 
# end
# 
# defmodule Plural.RUTest do
#   use ExUnit.Case
#   import Plural.RU, only: [ get_plural_form: 1 ]
# 
#   test "one" do
#     [ 1, 21, 31, 41, 51, 101, 121 ]
#       |> Enum.each( fn( count ) ->
#         assert get_plural_form( count ) == :one
#       end )
#   end
# 
#   test "few" do
#     [ 2, 3, 4, 22, 23, 24, 33, 34, 102, 103, 104, 122, 123, 124 ]
#       |> Enum.each( fn( count ) ->
#         assert get_plural_form( count ) == :few
#       end )
#   end
# 
#   test "many" do
#     [ 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 25, 35, 105, 110 ]
#       |> Enum.each( fn( count ) ->
#         assert get_plural_form( count ) == :many
#       end )
#   end
# 
#   test "other" do
#     [ 0.1, 1.1, 10.5, 10.0, 100.1 ]
#       |> Enum.each( fn( count ) ->
#         assert get_plural_form( count ) == :other
#       end )
#   end
# 
# end
# 
# 
# defmodule I18nTest do
#   use ExUnit.Case
#   import I18n, only: [ t: 2, t: 3 ]
# 
#   test "Notmal translations" do
#     assert t( "en", "title.user" ) == "user"
#   end
# 
# 
#   test "Pluralizarion: 1 item" do
#     assert t( "en", "title.user", 1 ) == "user"
#     assert t( "fr", "title.user", 1 ) == "utilisateur"
#   end
# 
#   test "Pluralizarion: 2 items" do
#     assert t( "en", "title.user", 2 ) == "users"
#     assert t( "fr", "title.user", 2 ) == "utilisateurs"
#   end
# 
# end
# ExUnit.run()
