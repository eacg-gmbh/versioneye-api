
module ProjectHelpers

  def file_attached?(file_obj)
    result = false

    if file_obj.nil? == false and file_obj.is_a?(ActionDispatch::Http::UploadedFile )
      result = true
    end

    result
  end

  def fetch_project_by_key_and_user(project_key, current_user)
    project = Project.by_user(current_user).where(project_key: project_key).shift
    if project.nil?
      project = Project.by_user(current_user).where(_id: project_key).shift
    end
    project
  end

  def destroy_project(project_id)
    project = Project.find_by_id(project_id)
    project.dependencies.each do |dep|
      dep.remove
    end
    project.remove
  end

  def upload_and_store file
    ProjectImportService.import_from_upload file, current_user, true
  rescue => e 
    return e.message
  end

end
