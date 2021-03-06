defmodule Template do

  import Html

  def render do
    markup do
      div id: "main" do
        h1 class: "title" do
          text "Welcome"
        end
      end
      div class: "row" do
        div do
          p do: text "Hello!"
        end
      end
      tag :table do
        tag :tr do
          for i <- 0..5 do
            tag :td, do: text( "Cell #{i}" )
          end
        end
      end
      div do
        text "XSS Protection <script>alert('vulnerable?');</script>"
      end
    end
  end

end

