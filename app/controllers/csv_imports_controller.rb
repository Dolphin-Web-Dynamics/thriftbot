class CsvImportsController < ApplicationController
  def index
    @csv_imports = CsvImport.recent
  end

  def new
    @csv_import = CsvImport.new
  end

  def create
    unless params[:file].present?
      redirect_to new_csv_import_path, alert: "Please select a CSV file."
      return
    end

    uploaded_file = params[:file]
    @csv_import = CsvImport.create!(filename: uploaded_file.original_filename, status: :pending)

    temp_path = Rails.root.join("tmp", "csv_import_#{@csv_import.id}_#{uploaded_file.original_filename}")
    File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }

    CsvImportService.new(@csv_import, temp_path.to_s).call

    File.delete(temp_path) if File.exist?(temp_path)

    if @csv_import.reload.failed?
      redirect_to csv_imports_path, alert: "Import failed. Check the error log for details."
    else
      redirect_to csv_imports_path, notice: "Successfully imported #{@csv_import.records_count} items from #{@csv_import.filename}."
    end
  end

  def destroy
    csv_import = CsvImport.find(params[:id])
    csv_import.items.each { |item| item.listings.destroy_all; item.sale&.destroy; item.destroy }
    csv_import.destroy

    redirect_to csv_imports_path, notice: "Import and all associated records deleted."
  end
end
