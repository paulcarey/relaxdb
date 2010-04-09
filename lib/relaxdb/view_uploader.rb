module RelaxDB
  
  class ViewUploader

    class << self
      
      # Methods must start and finish on different lines
      # The function declaration must start at the beginning of a line
      # As '-' is used as a delimiter, the view name may not contain '-'
      # Expected function declaration form is 
      #   function funcname-functype(doc) {
      # For example 
      #   function Users_followers-map(doc) {
      #
      # Builtin Erlang views may be specified by listing a one-line function
      # that contains only the builtin name. For example:
      #  function Users_followers-reduce() {
      #    _sum
      #  }
      #
      def upload(filename)
        lines = File.readlines(filename)
        dd = RelaxDB::DesignDocument.get(RelaxDB.dd)
        extract(lines) do |vn, t, f|
          dd.add_view(vn, t, f)
        end
        dd.save
      end
      
      def extract(lines)
        # Index of function declaration matches
        m = []

        0.upto(lines.size-1) do |p|
          line = lines[p]
          m << p if line =~ /^function[^\{]+\{/
        end
        # Add one beyond the last line number as the final terminator
        m << lines.size

        0.upto(m.size-2) do |i|
          declr = lines[m[i]]
          declr =~ /(\w)+-(\w)+/
          declr.sub!($&, '')
          view_name, type = $&.split('-')
          func = lines[m[i]...m[i+1]]
          
          # Cater for erlang view shortcuts e.g. _sum, _count etc.
          if func[1] =~ /\s*_\w+\s*$/
            func = func[1].strip
          else
            func = func.join
          end
          
          yield view_name, type, func
        end
      end

    end
    
  end
  
end
