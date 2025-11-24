class ImportsController < ApplicationController
  def new
  end

  def create
    if params[:file].blank?
      flash.now[:alert] = "Please choose a CSV file."
      return render :new, status: :unprocessable_entity
    end

    import = BookImport.new(params[:file])
    result = import.call

    session[:last_import_result] = {
      "total_rows"     => result.total_rows,
      "imported_count" => result.imported_count,
      "errors"         => result.errors
    }

    redirect_to import_path, notice: "Import completed."
  rescue StandardError => e
    flash.now[:alert] = "Import failed: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def show
    @result = session[:last_import_result]

    unless @result
      redirect_to new_import_path, alert: "No recent import found."
    end
  end
end
