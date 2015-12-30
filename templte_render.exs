defmodule Template do

  import Html

  def render do
    markup do
      tag :table do
        tag :tr do
          for i <- 0..5 do
            tag :td, do: text( "Cell #{i}" )
          end
        end
      end
    end
  end

end

