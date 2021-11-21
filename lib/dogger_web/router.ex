defmodule DoggerWeb.Router do
  use DoggerWeb, :router

  import DoggerWeb.BusinessAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {DoggerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_business
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DoggerWeb do
    pipe_through :browser
    resources "/owners", OwnerController
    resources "/pets", PetController
    resources "/stays", StayController

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", DoggerWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: DoggerWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", DoggerWeb do
    pipe_through [:browser, :redirect_if_business_is_authenticated]

    get "/businesses/register", BusinessRegistrationController, :new
    post "/businesses/register", BusinessRegistrationController, :create
    get "/businesses/log_in", BusinessSessionController, :new
    post "/businesses/log_in", BusinessSessionController, :create
    get "/businesses/reset_password", BusinessResetPasswordController, :new
    post "/businesses/reset_password", BusinessResetPasswordController, :create
    get "/businesses/reset_password/:token", BusinessResetPasswordController, :edit
    put "/businesses/reset_password/:token", BusinessResetPasswordController, :update
  end

  scope "/", DoggerWeb do
    pipe_through [:browser, :require_authenticated_business]

    get "/businesses/settings", BusinessSettingsController, :edit
    put "/businesses/settings", BusinessSettingsController, :update
    get "/businesses/settings/confirm_email/:token", BusinessSettingsController, :confirm_email
  end

  scope "/", DoggerWeb do
    pipe_through [:browser]

    delete "/businesses/log_out", BusinessSessionController, :delete
    get "/businesses/confirm", BusinessConfirmationController, :new
    post "/businesses/confirm", BusinessConfirmationController, :create
    get "/businesses/confirm/:token", BusinessConfirmationController, :edit
    post "/businesses/confirm/:token", BusinessConfirmationController, :update
  end
end
