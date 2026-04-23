class StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_student, only: [ :show, :edit, :update, :regenerate_qr ]
  before_action :require_admin, only: [:regenerate_qr]

  PER_PAGE = 10

  def index
    @searched = params[:q].present?
    return unless @searched

    base = Student.where("unaccent(name) ILIKE unaccent(?) OR registration ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    @page     = (params[:page] || 1).to_i
    @total    = base.count
    @has_more = @total > @page * PER_PAGE
    @students = base.order(:name).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def new
    @student = Student.new
    if params[:identifier].present?
      clean = params[:identifier].gsub(/\D/, "")
      CPF.valid?(clean) ? @student.cpf = clean : @student.registration = params[:identifier]
    end
  end

  def create
    @student = Student.new(student_params)

    if @student.save
      redirect_to students_path, notice: t("flash.students.created", name: @student.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @student.update(student_params)
      redirect_to @student, notice: t("flash.students.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def regenerate_qr
    QrCodeGeneratorService.generate_and_assign(@student)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "qr_code_student_#{@student.id}",
          partial: "students/qr_code",
          locals: { student: @student }
        )
      end
      format.html { redirect_to @student, notice: t("flash.students.qr_regenerated", name: @student.name) }
    end
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def student_params
    params.require(:student).permit(:name, :cpf, :registration, :email, :course)
  end
end
