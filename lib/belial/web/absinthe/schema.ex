defmodule Belial.Web.Absinthe.Schema do
  @moduledoc """
  Includes wanted/needed helper functions for using Absinthe
  with Belial for the Absinthe schema, as opposed to individual
  types.
  """

  defmacro __using__(_opts) do
    quote do
      use Absinthe.Schema

      import_types(Belial.Web.Absinthe.Scalar.NaiveDatetime)

      def middleware(middlewares, _field, %{identifier: identifier}) do
        case identifier do
          :subscription ->
            middlewares

          :mutation ->
            [ApolloTracing.Middleware.Tracing] ++ middlewares

          :query ->
            [
              ApolloTracing.Middleware.Tracing,
              ApolloTracing.Middleware.Caching
            ] ++ middlewares

          _ ->
            [
              ApolloTracing.Middleware.Tracing,
              ApolloTracing.Middleware.Caching
            ] ++ middlewares
        end
      end

      def plugins do
        [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
      end
    end
  end
end
