class FinderController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    return unless params[:cpf].present?

    cpf = params[:cpf].to_s.gsub(/[^0-9]/, "")

    unless cpf.length == 11 && CPF.valid?(cpf)
      flash.now[:alert] = t("finder.index.invalid_cpf")
      return
    end

    @person = Student.find_by(cpf: cpf) || Visitor.find_by(cpf: cpf)
    @person_type = @person.class.name.downcase.to_sym if @person

    if @person
      @recent_logs = @person.access_logs.order(created_at: :desc).limit(3)
    else
      flash.now[:alert] = t("finder.index.not_found")
    end
  end

  def search
    redirect_to finder_path(cpf: params[:cpf])
  end
end
