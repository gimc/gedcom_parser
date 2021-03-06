defmodule GedcomParser do

  @line_regex ~r/\s*(0|[1-9]+[0-9]*) (@[^@]+@ |)([A-Za-z0-9_]+)( [^\n\r]*|)/
  @tag_to_atom %{
    "NAME" => :name,
    "SEX" => :sex,
    "DATE" => :date,
    "OCCU" => :occupation,
    "FAMC" => :family_c_id,
    "FAMS" => :family_s_id,
    "NOTE" => :note_id,
    "DEAT" => :is_dead
  }

  @fact_tags ["BIRT", "DEAT", "CHAN"]

  @tag_to_fact_type %{
    "BIRT" => :birth,
    "DEAT" => :death,
    "CHAN" => :wtf_is_chan?
  }

  @fact_transforms %{
    "DEAT" => &Transforms.is_dead?/1
  }

  def process_file(filepath) do
    stream = File.stream!(filepath, [:utf8], :line)

    output = %{
      persons: [],
      person_facts: [],
      families: []
    }

    stream
    |> Stream.map(&(Regex.run(@line_regex, &1, capture: :all_but_first)))
    |> Stream.map(fn [level, pointer, tag, data] -> [level, pointer, tag, String.trim(data)] end)
    |> Enum.to_list
    |> process_lines(output)
  end

  defp process_lines([], output), do: output
  defp process_lines([[level, index, "INDI", _] | rest], output) do
    {lines, output} = process_person(rest, level, %{id: index}, output)
    process_lines(lines, output)
  end

  defp process_lines([_ | rest], output) do
    process_lines(rest, output)
  end

  # Person processing
  defp process_person([[level, _, tag, data] | rest], prev_level, person, output) when tag in @fact_tags do
    person =
      if Map.has_key?(@fact_transforms, tag),
        do: Map.put(person, @tag_to_atom[tag], @fact_transforms[tag].(data)),
      else: person

    {lines, fact} = process_person_fact(rest, level, %{person_id: person.id, type: @tag_to_fact_type[tag]})
    process_person(lines, level, person, Map.put(output, :person_facts, [fact|output.person_facts]))
  end

  defp process_person([[level, _, tag, data] = line | rest], prev_level, person, output) do
    process_person(rest, level, Map.put(person, @tag_to_atom[tag], data), output)
  end

  defp process_person([[level, _, _, _]| _] = lines, prev_level, person, output) when level < prev_level do
    {lines, Map.put(output, :persons, [person | output.persons])}
  end

  defp process_person([[level, index, tag, data]| rest], prev_level, person, output) when level < prev_level do
    # Don't recognise the tag, so ignore
    IO.inspect("Unknown tag: #{index} #{tag} #{data}")
    process_person(rest, level, person, output)
  end

  defp process_person([] = lines, _, person, output) do
    {lines, Map.put(output, :persons, [person | output.persons])}
  end

  # Person fact processing
  defp process_person_fact([[level, _, tag, data] | rest], prev_level, fact) when level == prev_level do
    process_person_fact(rest, level, Map.put(fact, @tag_to_atom[tag], data))
  end
  defp process_person_fact([[level, _, _, _] | _] = lines, prev_level, fact) do
    {lines, fact}
  end
end
