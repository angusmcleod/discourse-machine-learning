class DiscourseMachineLearning::RunSerializer < ::ApplicationSerializer
  attributes :label, :model_label, :dataset_label, :accuracy, :status
end