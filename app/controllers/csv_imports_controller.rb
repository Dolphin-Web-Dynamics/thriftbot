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
    sanitized_filename = sanitize_filename(uploaded_file.original_filename)
    @csv_import = CsvImport.create!(filename: sanitized_filename, status: :pending)

    tempfile = Tempfile.new([ "csv_import", ".csv" ], Rails.root.join("tmp").to_s)
    begin
      tempfile.binmode
      tempfile.write(uploaded_file.read)
      tempfile.rewind

      CsvImportService.new(@csv_import, tempfile.path).call
    ensure
      tempfile.close
      tempfile.unlink
    end

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

  private

  def sanitize_filename(filename)
    File.basename(filename).gsub(/[^a-zA-Z0-9._-]/, "_")
  end
end
