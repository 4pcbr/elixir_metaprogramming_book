defmodule Plural do

  def pluralize( item, locale ), do: pluralize( item, locale, 1 )
  def pluralize( item, _locale, _count ) when is_binary( item ), do: item
  def pluralize( item, locale, count ) when is_list( item ) do
    module = Module.concat( __MODULE__, String.upcase( locale ) )
    key = case :code.is_loaded( module ) do
      false -> raise "The locale #{locale} is not supported"
      true -> module.get_plural_form(count)
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
  def get_plural_form( count ) when is_integer( count ) and rem( count, 10 ) == 2 and not( rem( count, 100 ) in 12..14 ), do: :few
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

ExUnit.start()

defmodule I18nTest do
  use ExUnit.Case
  import I18n

  test "Notmal translations" do
    assert I18n.t( "en", "title.user" ) == "user"
  end


  test "Pluralizarion: 1 item" do
    assert I18n.t( "en", "title.user", count: 1 ) == "user"
    assert I18n.t( "fr", "title.user", count: 1 ) == "utilisateur"
  end

  test "Pluralizarion: 2 items" do
    assert I18n.t( "en", "title.user", count: 2 ) == "users"
    assert I18n.t( "fr", "title.user", count: 2 ) == "utilisateurs"
  end

end
ExUnit.run()
