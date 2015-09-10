module ProjectHelpers


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


  def upload_and_store file, visibility = 'private', name = nil
    project = ProjectImportService.import_from_upload file, current_user, true

    project.public = true  if visibility.to_s.eql?('public')
    project.public = false if visibility.to_s.eql?('private')
    project.name   = name  if !name.to_s.empty?

    project.save
    project
  rescue => e
    return e.message
  end


end
