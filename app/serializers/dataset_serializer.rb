class DiscourseMachineLearning::DatasetSerializer < ::ApplicationSerializer
  attributes :label, :model_label, :data

  def data
    ActiveModel::ArraySerializer.new(
      object.data,
      each_serializer: DiscourseMachineLearning::DataSerializer
    ).as_json
  end
end