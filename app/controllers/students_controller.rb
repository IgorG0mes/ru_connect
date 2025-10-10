class StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_student, only: [ :show, :edit, :update, :regenerate_qr ]
  before_action :require_admin, only: [:regenerate_qr]

  def index
    @students = Student.all
  end

  def new
    @student = Student.new
  end

  def create
    @student = Student.new(student_params)

    if @student.save
      redirect_to students_path, notice: "Aluno #{@student.name} cadastrado com sucesso! QR Code gerado."
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
      redirect_to @student, notice: "Aluno atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def regenerate_qr
    QrCodeGeneratorService.generate_and_assign(@student)

    redirect_to @student, notice: "Novo QR Code gerado e salvo para #{@student.name}."
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def student_params
    params.require(:student).permit(:name, :cpf, :registration, :email, :course)
  end
end
