class ImportsController < ApplicationController
  before_action :authenticate_import_user!
  def new
  end

  def new
  end

  def create
    uploaded_file = params[:file] || params.dig(:import, :file)

    if uploaded_file.blank?
      flash.now[:alert] = "Please choose a CSV file."
      return render :new, status: :unprocessable_entity
    end

    import = BookImport.new(uploaded_file)
    result = import.call

    session[:last_import_result] = {
      "total_rows"     => result.total_rows,
      "imported_count" => result.imported_count,
      "errors"         => result.errors
    }

    redirect_to import_path, notice: "Import completed."
  rescue StandardError => e
    Rails.logger.error(
      "Book import failed: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
    )
    flash.now[:alert] = "Import failed: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def show
    @result = session[:last_import_result]

    unless @result
      redirect_to new_import_path, alert: "No recent import found."
    end
  end

  def show
    @result = session[:last_import_result]

    unless @result
      redirect_to new_import_path, alert: "No recent import found."
    end
  end

  private

  def authenticate_import_user!
    authenticate_or_request_with_http_basic("Restricted Imports Area") do |username, password|
      secure_compare(username, ENV.fetch("IMPORT_USERNAME", "admin")) &&
        secure_compare(password, ENV.fetch("IMPORT_PASSWORD", "secret"))
    end
  end

  # Protects against timing attacks
  def secure_compare(a, b)
    return false if a.blank? || b.blank?
    ActiveSupport::SecurityUtils.secure_compare(a, b)
  end
end
