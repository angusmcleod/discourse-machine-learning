class DiscourseMachineLearning::ModelSerializer < ::ApplicationSerializer
  attributes :label, :type, :image_name, :image_status, :run_label, :run_status, :status
end